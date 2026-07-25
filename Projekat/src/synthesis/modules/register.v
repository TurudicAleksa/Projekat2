module register #(

    parameter DATA_WIDTH = 16
)(
    input clk,
    input rst_n,
    input cl,
    input ld,
    input [DATA_WIDTH-1:0] in,
    input inc,
    input dec,
    input sr,
    input ir,
    input sl,
    input il,
    output [DATA_WIDTH-1:0] out
);



    reg [DATA_WIDTH-1:0] out_reg=0, out_next;
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
            out_next<={DATA_WIDTH{1'b0}};
        else if(ld)
            out_next<=in;
        else if(inc)
            out_next<=out_reg + {{(DATA_WIDTH-1){1'b0}}, 1'b1};
        else if(dec)
            out_next<=out_reg - {{(DATA_WIDTH-1){1'b0}}, 1'b1};
        else if(sr)
        begin
            out_next<=out_reg >> 1;
            out_next[DATA_WIDTH-1]=ir;
        end
        else if(sl)
        begin
            out_next<=out_reg << 1;
            out_next[0]=il;
        end
    end
        
    



    
endmodule