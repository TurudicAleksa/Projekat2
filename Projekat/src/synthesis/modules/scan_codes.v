module scan_codes (
    input clk,
    input rst_n,
    input [15:0] code,
    input status,
    output reg control,
    output reg [3:0] num
);

    reg [15:0] last_code;

    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            control <= 1'b0;
            num <= 4'h0;
            last_code <= 16'h0000;
        end
        else begin
            last_code <= code;

            if (!status && control) begin
                control <= 1'b0;
                num <= 4'h0;
            end
            else if (status && !control && last_code != code) begin
                case (code)
                    // 1
                    16'hF016: begin
                        num <= 1;
                        control <= 1;
                    end
                    // 2
                    16'hF01E: begin 
                        num <= 2;
                        control <= 1;
                    end

                    // 3
                    16'hF026: begin 
                        num <= 3;
                        control <= 1;
                    end

                    // 4
                    16'hF025: begin 
                        num <= 4;
                        control <= 1;
                    end

                    // 5
                    16'hF02E: begin 
                        num <= 5;
                        control <= 1;
                    end

                    // 6
                    16'hF036: begin 
                        num <= 6;
                        control <= 1;
                    end

                    // 7
                    16'hF03D: begin 
                        num <= 7;
                        control <= 1;
                    end

                    // 8
                    16'hF03E: begin 
                        num <= 8;
                        control <= 1;
                    end

                    // 9
                    16'hF046: begin 
                        num <= 9;
                        control <= 1;
                    end

                    // 0
                    16'hF045: begin 
                        num <= 0;
                        control <= 1;
                    end

                    default: begin
                        num <= 0;
                        control <= 0;
                    end
                endcase

            end
        end
    end    
endmodule