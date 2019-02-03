task :cron => :environment do
  Member.find_by_sql("
    SELECT 
      members.id, 
      members.email, 
      members.name, 
      members.surname, 
      members.created_at, 
      members.updated_at 
    FROM members 
    LEFT JOIN family_members ON members.ID = family_members.member_id 
      WHERE family_members.member_id IS NULL AND members.created_at <= datetime('now', '-7 days')
    ;
    ").each do |member|
    # send user email saying hey! you need a family otherwise you'll be deleted!
  end

end