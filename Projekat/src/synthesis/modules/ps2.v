module ps2 (
    input clk,
    input rst_n,
    input ps2_clk,
    input ps2_data,
    output reg [15:0] code
);

    reg [7:0] tmp;
    reg [3:0] cnt;
    reg parity;

    wire deb_clk;

    debouncer ps2_debouncer(
        .clk(clk), .rst_n(1'b1), .in(ps2_clk), .out(deb_clk)
    );

    always @(negedge deb_clk, negedge rst_n)
    begin
        if(!rst_n) begin
            cnt <= 4'h0;
            tmp <= 8'h00;
            parity <= 1'b0;
        end
        else begin
            case (cnt)
            0: begin
                if (!ps2_data) begin
                    cnt <= 1;                    
                end
            end
            1, 2, 3, 4, 5, 6, 7, 8: begin
                tmp <= {ps2_data, tmp[7:1]};
                cnt <= cnt + 1;
            end
            9: begin
                parity <= ps2_data;
                cnt <= 10;
            end
            10: begin
                code <= {code[7:0], tmp};
                cnt <= 0;
            end
            default:
                cnt <= 0; 
        endcase
        end
    end
    
endmodule