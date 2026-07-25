module register (
    clk,
    rst_n,
    cl,
    ld,
    in,
    inc,
    dec,
    sr,
    ir,
    sl,
    il,
    out
);

    input clk; 
    input rst_n;
    input cl;
    input ld;
    input [3:0] in;
    input inc;
    input dec;
    input sr;
    input ir;
    input sl;
    input il;
    output [3:0] out;

    reg [3:0] out_reg=4'b0000, out_next;
    assign out = out_reg;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            out_reg <= 0;
        else
            out_reg <= out_next;

    end
    
    always @(cl,ld,in,inc,dec,sr,ir,sl,il) begin
        out_next=out_reg;
        if(cl)
            out_next<=4'b0000;
        else if(ld)
            out_next<=in;
        else if(inc)
            out_next<=out_reg + {{3{1'b0}}, 1'b1};
        else if(dec)
            out_next<=out_reg - {{3{1'b0}}, 1'b1};
        else if(sr)
        begin
            out_next<=out_reg >> 1;
            out_next[3]=ir;
        end
        else if(sl)
        begin
            out_next<=out_reg << 1;
            out_next[0]=il;
        end
    end
        
    



    
endmodule