/* **************************************************** *
 *  	Quotes Bot by Kito (irc.vortexirc.com)		*
 *	   This script requires MYSQLTCL		*
 * Explaination:					*
 *	This botscript is used to store quotes to a 	*
 *	MySQL Database. 				*
 * Modifying and licensing:				*
 *	You may modify this script but you are not 	*
 *	allowed to remove the credits!			*
 * Other Advises:					*
 *	NAME YOUR BOT "Quotes"!				*
 *	Install the package mysqltcl BEFORE		*
 * **************************************************** */

#####  Bot Commands ######
#
#	.addquote QUOTE
#	.quotes
#	.delquote ID (for chanops)
#	/msg bot add #chan (for admin)
#	!join #chan (admin)
#	!part #chan (admin)
#	!rehash Quotes
#	ONJOIN message
#	/msg bot del #chan (admin)
#	.findquote AUTHOR
#	.quote ID
#	.helpquotes
#
###########################

/* [REQUIRED] NickServ Password
 * 	Used to identify to Nickserv
 */

set nickserv "PASSWORD_HERE"

/* [REQUIRED] Admin Nickname
 *      Used to control the bot
 */

set admin "NICKNAME_HERE"

/* [REQUIRED] NickServ Password
 *      Used to identify to Nickserv
 */

set dbuser "user"
set dbpass "db_password"
set dbname "db_name"
set dbtable "db_table_name"

/* [REQUIRED] DB Structure
  	Make your database look like this:

	ID  | AUTHOR | CHANNEL | CONTENT
     -------------------------------------
     autoid | TEXT   |  TEXT   |  TEXT
*/

package require mysqltcl

bind evnt - init-server do:nickserv
proc do:nickserv init-server {
                putquick "PRIVMSG NickServ :id $nickserv"
}

bind pub - !join do_join
        proc do_join {nick uhost hand chan text} {
                if {$nick == $admin} {
                        [channel add [lindex $text 0]]
                }
        }

bind pub - !part do_part
        proc do_part {nick uhost hand chan text} {
                if {[lindex $text 0] == "Quotes" && $nick == $admin} {
                        [channel remove [lindex $text 1]]
                }
        }

bind pub - !rehash do_rehash
        proc do_rehash {nick uhost hand chan text} {
        if {[lindex $text 0] == "Quotes" || [lindex $text 0] == "quotes"} {
		rehash
		puthelp "PRIVMSG $chan :*** Rehashed."
	}
	}


bind msg - add quotes_add
	proc quotes_add {nick uhost hand text} {
		if {$nick == $admin} {
			channel add [lindex $text 0]
		} else {
			putserv "PRIVMSG $nick :No access."
		}
	}

bind msg - del quotes_del
        proc quotes_del {nick uhost hand text} {
                if {$nick == $admin} {
                        channel remove [lindex $text 0]
                } else {
                        putserv "PRIVMSG $nick :No access."
                }
        }

bind join - * join_it
proc join_it {nick uhost hand chan} {
	global botnick
	if {[isbotnick $nick]} {
		putquick "PRIVMSG $chan :SYNTAX: .addquote <quote>, .delquote <id>, .quote <id>, .quotes , .findquote <author>"
		putquick "PRIVMSG $chan :Help on: .helpquotes"
# Uncomment this if the bot has ircop priviledges
#		putquick "MODE $chan +oe $botnick $botnick" /* This works if the bot gains ircoperator access */
	}
}
 
bind pub - .addquote add_quote
	proc add_quote {nick uhost hand chan text} {
		set db_handle [mysqlconnect -host $dbhost -user $dbuser -password $dbpass -db $dbname]
                set add "INSERT INTO $dbtable VALUES('', '$nick', '$chan', '[lrange $text 0 end]')"
              	mysqlexec $db_handle $add
                set getid "SELECT id FROM quote WHERE content='[lrange $text 0 end]' AND channel='$chan'"
                set id1 [mysqlquery $db_handle $getid]
                set id [lindex [mysqlnext $id1] 0]

		putserv "PRIVMSG $chan :Quote has been added. (ID: $id)"
	}
		
bind pub - .delquote del_quote
        proc del_quote {nick uhost hand chan text} {
		if {[isop $nick $chan] == 1} {
                set db_handle [mysqlconnect -host $dbhost -user $dbuser -password $dbpass -db $dbname]
                set del "DELETE FROM $dbtable WHERE id='[lindex $text 0]'"
                mysqlexec $db_handle $del
		mysqlclose	
		putserv "PRIVMSG $chan :Quote has been deleted. (ID: [lindex $text 0])"
        	} else {
		putserv "PRIVMSG $chan :Only Channel operators (+o) can delete quotes."
		}
	}

bind pub - .quote show_quote
        proc show_quote {nick uhost hand chan text} {
                set db_handle [mysqlconnect -host $dbhost -user $dbuser -password $dbpass -db $dbname]
                set getquote "SELECT content FROM $dbtable WHERE id='[lindex $text 0]' AND channel='$chan'"
                set quote1 [mysqlquery $db_handle $getquote]
                set quote [lindex [mysqlnext $quote1] 0]
                set getauthor "SELECT author FROM $dbtable WHERE id='[lindex $text 0]' AND channel='$chan'"
                set author1 [mysqlquery $db_handle $getauthor]
                set author [lindex [mysqlnext $author1] 0]
		if {$quote == ""} {
		putserv "PRIVMSG $chan :Quote not found!"
		} else {
                putserv "PRIVMSG $chan :\"$quote\" Author: $author"
        	}
	}

bind pub - .quotes show_quotes
        proc show_quotes {nick uhost hand chan text} {
                set db_handle [mysqlconnect -host $dbhost -user $dbuser -password $dbpass -db $dbname]
                set getids "SELECT id FROM $dbtable WHERE channel='$chan' ORDER BY RAND()"
                #set ids1 [mysqlquery $db_handle $getids]
                set id [mysqlsel $db_handle $getids -list]
                if { $id == "" } {
		putserv "PRIVMSG $chan :No Quotes added."
		} else {
		putserv "PRIVMSG $chan :IDs: $id"
        	}
	}

bind pub - .findquote find_quotes
        proc find_quotes {nick uhost hand chan text} {
                set db_handle [mysqlconnect -host $dbhost -user $dbuser -password $dbpass -db $dbname]
                set getids "SELECT id FROM $dbtable WHERE author='[lindex $text 0]' AND channel='$chan' ORDER BY RAND()"
                set id [mysqlsel $db_handle $getids -list]
                if { $id == "" } {
                putserv "PRIVMSG $chan :No Quotes found."
                } else {
                putserv "PRIVMSG $chan :Quotes made by [lindex $text 0]: $id"
                }
        }

bind pub - .helpquotes help_quotes
	proc help_quotes {nick uhost hand chan text} {
		putserv "PRIVMSG $chan :.addquote <quote>, .delquote <quote>, .quotes, .quote <id>, .findquote <author>"
	}


/* Credits: Kito / You may modify this script. You may not spread the modified script. */
