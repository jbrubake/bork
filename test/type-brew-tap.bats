#!/usr/bin/env bats

. test/helpers.sh
brew-tap () { . $BORK_SOURCE_DIR/types/brew-tap.sh $*; }

setup () {
    respond_to "uname -s" "echo Darwin"
    respond_to "brew tap" "cat $fixtures/brew-tap-list.txt"
    respond_to "brew tap --list-pinned" "cat $fixtures/brew-tap-pinned.txt"
}

@test "brew-tap status reports missing when untapped" {
    run brew-tap status some/tap
    [ "$status" -eq $STATUS_MISSING ]
}

@test "brew-tap status reports partial when installed but missing pin status" {
    run brew-tap status railwaycat/emacsmacport --pin
    [ "$status" -eq $STATUS_PARTIAL ]
}

@test "brew-tap status reports partial when installed but has pin status when it shouldn't" {
    run brew-tap status homebrew/games
    [ "$status" -eq $STATUS_PARTIAL ]
}

@test "brew-tap status reports ok when installed has correct no-pin status" {
    run brew-tap status railwaycat/emacsmacport
    [ "$status" -eq $STATUS_OK ]
}

@test "brew-tap status reports ok when provided tap name has capitals" {
    run brew-tap status Caskroom/cask
    [ "$status" -eq $STATUS_OK ]
}

@test "brew-tap status reports ok when installed has correct yes-pin status" {
    run brew-tap status homebrew/games --pin
    [ "$status" -eq $STATUS_OK ]
}


@test "brew-tap install installs tap" {
    run brew-tap install homebrew/science
    [ "$status" -eq 0 ]
    run baked_output
    [ "$output" = 'brew tap homebrew/science' ]
}

@test "brew-tap install installs tap with pin" {
    run brew-tap install homebrew/science --pin
    [ "$status" -eq 0 ]
    run baked_output
    [[ "brew tap homebrew/science" == ${lines[0]} ]]
    [[ "brew tap-pin homebrew/science" == ${lines[1]} ]]
}

@test "brew-tap upgrade with pin adds pin" {
    run brew-tap upgrade homebrew/science --pin
    [ "$status" -eq 0 ]
    run baked_output
    [ "$output" = "brew tap-pin homebrew/science" ]
}

@test "brew-tap upgrade without pin removes pin" {
    run brew-tap upgrade homebrew/science
    [ "$status" -eq 0 ]
    run baked_output
    [ "$output" = "brew tap-unpin homebrew/science" ]
}

@test "brew-tap inspect: returns FAILED_PRECONDITION without brew exec" {
    respond_to "which brew" "return 1"
    run brew-tap inspect
    [ "$status" -eq $STATUS_FAILED_PRECONDITION ]
}

@test "brew-tap inspect: returns OK if preconditions met" {
    run brew-tap inspect
    [ "$status" -eq $STATUS_OK ]
}

@test "brew-tap remove untaps tap" {
    run brew-tap remove homebrew/science
    [ "$status" -eq 0 ]
    run baked_output
    [ "$output" = 'brew untap homebrew/science' ]
}
