# https://docs.google.com/spreadsheets/d/1i41fsmLf7IjfYbr1coTo9V4uk3t1GXAGgt0aOeCkeeA/edit#gid=0

BEGIN {FS="\",\""}

NR == 1 {


    for(i=1;i<=NF;i++) {

        sub("\"", "", $i)

        if (debug) {
            printf("%d <%s>\n", i, $i)
        }

        if ($i ~ /^Paddle Number /)
            PADDLE = i
        if ($i ~ /^Paddle End \(A\/B\) /)
            PADDLE_END = i
        if ($i ~ /^Panel Number.*/)
            PANEL = i
        if ($i ~ /^LTB Harting Connection.*/)
            DSI = i
        if ($i ~ /^RB Number-Channel RB Number.*/)
            RB = i
    }
    if (debug) {
        print (PADDLE)
        print (PADDLE_END)
        print (PANEL)
        print (DSI)
        print (RB)
    }
    next
}

{

    for(i=1;i<=NF;i++) {
        sub("\"", "", $i)
    }

    paddle_num = int($PADDLE)
    panel_num = int($PANEL)
    paddle_end = $PADDLE_END
    dsi_input = paddle_num # TODO: change to int($DSI) when the mapping is done

    split($RB, rb_and_input, "-")
    rb_num = int(rb_and_input[1])
    rb_input = int(rb_and_input[2])
    rb_enum = 8*(rb_num-1)+(rb_input-1)

    # use a regex for this instead, E-X225
    # E-X[0-9][0-9][0-9]
    #if ($PANEL ~ "^E-X[0-9][0-9][0-9]") {
    if ($PANEL == "")
        is_corner = 1
    else
        is_corner = 0

    # skip the B paddles
    if (paddle_end == "B")
        next

    # errors
    if (paddle_end != "A" && paddle_end != "B")
        exit 1

    # the cube is panels 1-6, umbrella is 7-13, and cortina will be 14-21
    if (panel_num == 2) {
        station="cube_bot"
        cnt = ++cube_bot_cnt
    }
    else if (panel_num >= 1 && panel_num <= 6) {
        station="cube"
        cnt = ++cube_cnt
    }
    else if (is_corner) {
        station="cube_corner"
        cnt = ++corner_cnt
    }
    else if (panel_num >= 7 && panel_num <= 13) {
        station="umbrella"
        cnt = ++umbrella_cnt
    }
    else if (panel_num >= 14 && panel_num <= 21) {
        station="cortina"
        cnt = ++cortina_cnt
    } else {
        station="xxxx"
        exit 1
    }

    # count from zero in the firmware
    dsi_input  -= 1
    cnt        -= 1

    # vhdl output
    outputs[station][cnt] = \
        sprintf("    %s(%d) <= hits_i(%d); -- panel=%d paddle=%d station=%s (%d)",
                station, cnt, dsi_input, panel_num, paddle_num, station, cnt)

    maps[NR] = \
        sprintf("  rb_ch_bitmap_o(%3d) <= hits_bitmap_i(%d);", rb_enum, dsi_input)

}

END {

    if (print_hitmask) {
        for (i in outputs) {
            for (j in outputs[i] ) {
                print outputs[i][j]
            }
            print ""
        }
    }

    if (print_rbmap) {
        for (i in maps) {
            print maps[i]
        }
    }

}
