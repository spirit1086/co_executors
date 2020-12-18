class CreateIssueUsers < ActiveRecord::Migration[5.2]
  def change
     create_join_table :issues, :users, table_name: :issue_users
  end
end
