module clk_div #(
    parameter DIVISOR = 50_000_000
)
(
    input clk,
    input rst_n,
    output out
);


integer timer_reg, timer_next;
reg out_next, out_reg;

assign out = out_reg;

always @(posedge clk, negedge rst_n)
    if (!rst_n) begin
        timer_reg <= 0;
        out_reg <= 1'b0;
    end
    else begin
        timer_reg <= timer_next;
        out_reg <= out_next;
    end
always @(*) begin
    timer_next = timer_reg;
    out_next = out_reg;
    if(timer_reg > DIVISOR/2) begin
        out_next = 1'b1;    
    end
    else if(timer_reg == DIVISOR) begin
        out_next = 1'b0;
        timer_next = 0;
    end
    timer_next = timer_reg+1;
    
end

endmodule