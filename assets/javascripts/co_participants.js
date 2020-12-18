$(document).ready(function()
{
    var multiple_users;
    console.log('соисполнители');
    co_participants = $(".assigned-users").remove();
    $(".assigned-to").after(co_participants);

    co_participants_multiple_field_box = $("#issue_users_id-box").remove();
    $("#issue_assigned_to_id").closest("p").after(co_participants_multiple_field_box);
   
    $(document).on("change","#issue_tracker_id",function()
    {
        console.log("#issue_tracker_id changed");
        let nTimer = setInterval(function()
        {
            let indicator = document.getElementById("ajax-indicator");
            if(indicator.getAttribute("style") =='display: none;')
            {
                co_participants_multiple_field_box = $("#issue_users_id-box").remove();
                co_participants_multiple_field_box = multiple_users ? multiple_users : co_participants_multiple_field_box;
                $("#issue_assigned_to_id").closest("p").after(co_participants_multiple_field_box);
                $("#issue_users_id").select2();
                console.log('clearInterval');
                clearInterval(nTimer); // тут уже идет отключение интервала поскольку indicator отловили
            }
        }, 100);        
    });

    $(document).on("change","#issue_project_id",function()
    {
        var project_permission;
        project_id = $(this).find(":selected").val();
        
        console.log('selected project_id: '+project_id);
        if(project_id)
        {
            $.post('/is-show-co-participants', {project_id: project_id})
                .done(function( data )
                {
                    project_permission = data;
                    console.log(data);
                })
                .fail(function(error)
                {
                    console.log(error);
                });
        }    
        
        console.log("#issue_project_id changed");
        let nTimer2 = setInterval(function()
        {
            let indicator2 = document.getElementById("ajax-indicator");
            if(indicator2.getAttribute("style") =='display: none;')
            {
                co_participants_multiple_field_box = $("#issue_users_id-box").remove();
                $("#issue_assigned_to_id").closest("p").after(co_participants_multiple_field_box);
                $("#issue_users_id").select2();
                console.log('clearInterval');
                clearInterval(nTimer2); // тут уже идет отключение интервала поскольку indicator отловили
                if(!project_permission)
                {
                    $("#issue_users_id-box").css('display','none');
                    $("#issue_users_id option:selected").removeAttr("selected");
                }  
                else
                {
                    if($("#issue_users_id-box").length>0) 
                    {
                        $("#issue_users_id-box").removeAttr('style');
                        console.log('#issue_users_id-box has');
                    }
                    else
                    {
                        console.log('#issue_users_id-box not');
                        multiple_users='<p id="issue_users_id-box">\
                            <label for="issue_users_id">Выберите соучастников задачи</label>\
                            <select name="issue[users_id][]" id="issue_users_id" multiple="" style="width:100%" data-select2-id="issue_users_id" tabindex="-1" class="select2-hidden-accessible" aria-hidden="true">\
                                <option value="">Выберите соучастников задачи</option>\
                                <option value="5">Иванов Иван</option>\
                                <option value="8">Хасенов Жансур</option>\
                                <option value="6">Петерсен Рон</option>\
                                <option value="1">Admin Redmine</option>\
                                <option value="9">Куратов Куратор</option>\
                            </select>\
                        </p>';
                        $("#issue_assigned_to_id").closest("p").after(multiple_users);
                    }    
                    $("#issue_users_id").select2();
                }    
            }
        }, 100);
    });

    
});