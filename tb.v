`include "top.v"
`include "encrypt.v"
`include "decrypt.v"
`include "keyExpan.v"
module tb ();

reg clk , tdi ,tms , trst ;
reg [127:0]input_key , a , b ;

///////----------encryption part
reg e_en ;
reg [127:0]plaintext , e_round_key , encrypted_result;
wire [127:0]ciphertext ;
wire [3:0]e_round ;

///////----------encryption part

////////----------key expansion part
reg ke_en ;
reg [3:0]ke_round ;
wire [127:0]ke_round_key ;

////////----------key expansion part
reg d_en ;
reg [127:0]d_ciphertext , d_round_key ;
wire [127:0] d_plaintext ;
wire [3:0] d_round ; 
wire d_dn ;
////////----------decryption part



////////----------decryption part


reg check = 0 ;  
wire tdo , e_dn;
wire [127:0]c ;

top top_inst(clk , tdi , tms , trst , input_key , a , b , c , tdo ) ;
encrypt e_inst(clk , e_en , plaintext , ciphertext , e_round , e_round_key , e_dn) ;
keyExpan ke_inst(clk , ke_en , ke_round , input_key , ke_round_key) ;
decrypt d_inst(clk , d_en , encrypted_result , d_plaintext , d_round , d_round_key , d_dn) ;

always #5 clk = ~clk ;
///////////////////////
///////////////////////
// 1 ) encrypt a 
// 2 ) send the encrypted a serially in the chip
// 3 ) decrypt a
// 4 ) encrypt b
// 5 ) send the encrypted b serially in the chip . Along with this the a will reach ahead in the chip
// 6 ) decrypt b
// 7 ) send that to it's intended position in the chip
// 8 ) solve a + b 
// 9 ) send the result to encrypt 
// 10 ) encrypt the result
// 11 ) send the result serially out the chip , collect it 
// 12 ) decrypt the result 
///////////////////////
///////////////////////
integer i ;
initial begin

    e_en = 0 ;
    d_en = 0 ;
    trst = 0 ; 
    clk = 0 ;
    tms = 0 ; 
    a = 128'h00000000000000000000000000000007 ;
    b = 128'h00000000000000000000000000000008 ;
    
    // b = 128'h3243f6a8885a308d313198a2e0370734 ;
    // b = 128'h00000012 ; //  to demonstrate normal operation 
    // plaintext = a ; // encrypting a
     
    plaintext = a ; // encrypting a 
    input_key = 128'h2b7e151628aed2a6abf7158809cf4f3c ;
    @(negedge clk) ;
    ke_en = 1 ;
    // first I need to enable encryption from here and make it encrypt the a and b , then we use tms in the chip 
    // to regulate the fsm 

    repeat(10)@(posedge clk) ;
    
    @(negedge clk) ;
    trst = 1 ;
    repeat(1)@(posedge clk) ;
    @(negedge clk) ;
    ke_en = 0 ;
    // input_key = 128'h2b7e151628aed2a6abf7158809cf4f3c ;
    e_round_key = input_key ; 
     
    tms = 0 ;
    
    // wait in the idle state for 10 cycle for the encryption to be completed 
    repeat(2)@(posedge clk) ;
    e_en = 1 ;
    wait(e_inst.done) ; // encryption of a done
    e_en = 0 ;
    
    // now that we have the a encrypted , we need to send it in the chip serially
    // we will use tms to regulate the fsm in the chip
    tms = 1 ;
    @(posedge clk) ;
    @(posedge clk) ;
    
    @(negedge clk) ;
    // @(posedge clk) ;

    // start reading data here 
    check = 1 ;
    for( i = 0 ; i < 128 ; i = i + 1)begin
        tdi = ciphertext[i] ;
        if(i == 127)begin
            tms = 0 ;
        end
        @(negedge clk) ;
    end
    // data sent to the bsc(d) 
    // now we need to decrypt the a
    // use tms to put the chip in d state 
    // idle to decrypt -> 
    // tms = 1 ; @(posedge clk ); tms = 0 ;@(posedge clk) ;
    // tms = 0 ;@(posedge clk) ; tms = 0 ;@(posedge clk) ; 
    // tms = 1 ; @(posedge clk) ; 
    tms = 1 ; @(negedge clk ); tms = 0 ;@(negedge clk) ;
    tms = 0 ;@(negedge clk) ; tms = 0 ;@(negedge clk) ; 
    tms = 1 ; @(negedge clk) ; 
    // repeat(10)@(posedge clk) ;
    // repeat(3)@(posedge clk) ;
    wait(top_inst.d_inst.done_d) ;
    tms = 0 ; @(negedge clk ); tms = 0 ;@(negedge clk) ;
    tms = 0 ;@(negedge clk) ; tms = 0 ;@(negedge clk) ;  
    
    // now we need to start sending in b ;
    // first we need to encrypt b
    plaintext = b ;
    e_en = 1 ;
    wait(e_inst.done) ; // encryption of a done
    e_en = 0 ;
    @(posedge clk) ;
    // sending in encrypted b serially
    tms = 1 ;@(negedge clk) ; tms = 1 ;@(negedge clk) ; 
    for( i = 0 ; i < 128 ; i = i + 1)begin
        tdi = ciphertext[i] ;
        if(i == 127)begin
            tms = 0 ;
        end
        @(negedge clk) ;
    end 
    // data sent to the bsc(d)
    // now we need to decrypt b
    // use tms to put the chip in d state
    tms = 1 ; @(negedge clk ); tms = 0 ;@(negedge clk) ;
    tms = 0 ;@(negedge clk) ; tms = 0 ;@(negedge clk) ; 
    tms = 1 ; @(negedge clk) ; 
    wait(top_inst.d_inst.dn) ;
    // so now we are done with the decryption of b
    // now we need to send it to it's intended position in the chip
    @(posedge clk) ;
    tms = 0 ;@(negedge clk) ; tms = 1 ;@(negedge clk) ;
    tms = 1 ;@(negedge clk) ;
     for( i = 0 ; i < 128 ; i = i + 1)begin
        tdi = 0 ;
        if(i == 127)begin
            tms = 0 ;
        end
        @(negedge clk) ;
    end
    // we are in
    // now we need to solve a + b
    // go to the capture state 
    @(posedge clk) ;
    tms = 1 ;@(negedge clk) ; tms = 0 ;@(negedge clk) ;
    tms = 1 ;@(negedge clk) ;
    @(posedge clk) ;
    @(posedge clk) ;
    // now we need to send the result to encrypt
    // now we need to send it serially to encrypt 
    @(posedge clk) ;
    tms = 0 ;@(negedge clk) ; tms = 1 ;@(negedge clk) ;
    tms = 1 ;@(negedge clk) ;
     for( i = 0 ; i < 128 ; i = i + 1)begin
        tdi = 0 ;
        if(i == 127)begin
            tms = 0 ;
        end
        @(negedge clk) ;
    end
    // now we need to encrypt the result
    @(posedge clk) ;
    tms = 1 ;@(negedge clk) ; tms = 0 ;@(negedge clk) ;
    tms = 0 ;@(negedge clk) ; tms = 1 ;@(negedge clk) ;
    // wait(top_inst.e_inst.dn) ;
    repeat(11)@(posedge clk) ;  
    @(negedge clk) ;tms = 0 ;
    // now we need to send the result serially out the chip
    // $display("data encrypted in the chip %b -> " , top_inst.e_inst.ciphertext) ;
    @(posedge clk) ;
    tms = 0 ;@(negedge clk) ; tms = 1 ;@(negedge clk) ;
    tms = 1 ;@(negedge clk) ;
    @(negedge clk ) ;
     for( i = 0 ; i < 128 ; i = i + 1)begin
        tdi = 0 ;
        encrypted_result[i] = tdo ;
        if(i == 127)begin
            tms = 0 ;
        end
        @(negedge clk) ;
    end
    // $display("data encrypted in the chip %b -> " , encrypted_result) ; 
    // now we need to decrypt the result outside the chip 
    d_en = 1 ;
    wait(d_inst.done_d) ;

    $display("%2d+%2d=%2d " ,a,b,d_plaintext)   ;
    d_en =  0 ;
    check = 0 ;
    #50
    $stop ;

end

always @ * begin
    if(e_en == 1)begin
    ke_round <= e_round ;
      e_round_key <= ke_round_key ;
    end
    else if(d_en == 1)begin
        ke_round <= d_round ;
        d_round_key <= ke_round_key ;
    end 
    else begin end
      
end

initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0,tb);
end
endmodule