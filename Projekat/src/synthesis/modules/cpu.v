module cpu #(
    parameter ADDR_WIDTH = 6,
    parameter ADDR_HIGH = ADDR_WIDTH - 1,
    parameter DATA_WIDTH = 16,
    parameter DATA_HIGH = DATA_WIDTH - 1
) (
    input clk,
    input rst_n,
    input [DATA_HIGH:0] mem,
    input [DATA_HIGH:0] in,
    input control,
    output reg status,
    output reg we,
    output [ADDR_HIGH:0] addr,
    output reg [DATA_HIGH:0] data,
    output reg [DATA_HIGH:0] out,
    output [ADDR_HIGH:0] pc,
    output [ADDR_HIGH:0] sp
    // ,output [15:0] test
    // ,output [5:0] test_state
);

    localparam 
        IR_WIDTH = DATA_WIDTH * 2, 
        IR_HIGH = IR_WIDTH - 1
    ;

    wire [IR_HIGH:0] ir_out;
    wire [DATA_HIGH:0] mdr_out, acc_out, alu_out;

    reg [ADDR_HIGH:0] pc_in, sp_in, mar_in;
    reg [IR_HIGH:0] ir_in;
    reg [DATA_HIGH:0] acc_in, alu_a, alu_b;

    ///////////

    wire [ADDR_HIGH:0] src_out, dst_out;
    wire [DATA_HIGH:0] cnt_out;

    reg src_cl, src_ld, src_inc, src_dec, src_sr, src_ir, src_sl, src_il;
    reg dst_cl, dst_ld, dst_inc, dst_dec, dst_sr, dst_ir, dst_sl, dst_il;
    reg cnt_cl, cnt_ld, cnt_inc, cnt_dec, cnt_sr, cnt_ir, cnt_sl, cnt_il;

    ///////////

    reg pc_cl, pc_ld, pc_inc, pc_dec, pc_sr, pc_ir, pc_sl, pc_il;
    reg sp_cl, sp_ld, sp_inc, sp_dec, sp_sr, sp_ir, sp_sl, sp_il;
    reg ir_cl, ir_ld, ir_inc, ir_dec, ir_sr, ir_ir, ir_sl, ir_il;
    reg mar_cl, mar_ld, mar_inc, mar_dec, mar_sr, mar_ir, mar_sl, mar_il;
    reg mdr_cl, mdr_ld, mdr_inc, mdr_dec, mdr_sr, mdr_ir, mdr_sl, mdr_il;
    reg acc_cl, acc_ld, acc_inc, acc_dec, acc_sr, acc_ir, acc_sl, acc_il;

    reg [2:0] alu_oc;

    register #(ADDR_WIDTH) pc_reg (
        .clk(clk), .rst_n(rst_n), .cl(pc_cl), .ld(pc_ld),
        .in(pc_in), .inc(pc_inc), .dec(pc_dec), .sr(pc_sr),
        .ir(pc_ir), .sl(pc_sl), .il(pc_il), .out(pc)
    );

    register #(ADDR_WIDTH) sp_reg (
        .clk(clk), .rst_n(rst_n), .cl(sp_cl), .ld(sp_ld),
        .in(sp_in), .inc(sp_inc), .dec(sp_dec), .sr(sp_sr),
        .ir(sp_ir), .sl(sp_sl), .il(sp_il), .out(sp)
    );

    register #(IR_WIDTH) ir_reg (
        .clk(clk), .rst_n(rst_n), .cl(ir_cl), .ld(ir_ld),
        .in(ir_in), .inc(ir_inc), .dec(ir_dec), .sr(ir_sr),
        .ir(ir_ir), .sl(ir_sl), .il(ir_il), .out(ir_out)
    );

    register #(ADDR_WIDTH) mar_reg (
        .clk(clk), .rst_n(rst_n), .cl(mar_cl), .ld(mar_ld),
        .in(mar_in), .inc(mar_inc), .dec(mar_dec), .sr(mar_sr),
        .ir(mar_ir), .sl(mar_sl), .il(mar_il), .out(addr)
    );

    register #(DATA_WIDTH) mdr_reg (
        .clk(clk), .rst_n(rst_n), .cl(mdr_cl), .ld(mdr_ld),
        .in(mem), .inc(mdr_inc), .dec(mdr_dec), .sr(mdr_sr),
        .ir(mdr_ir), .sl(mdr_sl), .il(mdr_il), .out(mdr_out)
    );

    register #(DATA_WIDTH) acc_reg (
        .clk(clk), .rst_n(rst_n), .cl(acc_cl), .ld(acc_ld), 
        .in(acc_in), .inc(acc_inc), .dec(acc_dec), .sr(acc_sr),
        .ir(acc_ir), .sl(acc_sl), .il(acc_il), .out(acc_out)
    );

    ////////////////

    register #(ADDR_WIDTH) src_reg (
        .clk(clk), .rst_n(rst_n), .cl(src_cl), .ld(src_ld),
        .in(ir_in[7:4]), .inc(src_inc), .dec(src_dec), .sr(src_sr),
        .ir(src_ir), .sl(src_sl), .il(src_il), .out(src_out)
    );

    register #(ADDR_WIDTH) dst_reg (
        .clk(clk), .rst_n(rst_n), .cl(dst_cl), .ld(dst_ld),
        .in(ir_in[11:8]), .inc(dst_inc), .dec(dst_dec), .sr(dst_sr),
        .ir(dst_ir), .sl(dst_sl), .il(dst_il), .out(dst_out)
    );

    register #(DATA_WIDTH) cnt_reg (
        .clk(clk), .rst_n(rst_n), .cl(cnt_cl), .ld(cnt_ld),
        .in(ir_in[31:16]), .inc(cnt_inc), .dec(cnt_dec), .sr(cnt_sr),
        .ir(cnt_ir), .sl(cnt_sl), .il(cnt_il), .out(cnt_out)
    );

    ////////////////

    alu #(DATA_WIDTH) alu_inst (.oc(alu_oc), .a(alu_a), .b(alu_b), .f(alu_out));

    localparam // states
        START = 0,

        IF1 = 1, IF2 = 2, IF3 = 3, IF4 = 4,
            IF5 = 5, IF6 = 6, IF7 = 7, IF8 = 8,

        ID = 9, 
        ID_OP1_DIR1 = 10, ID_OP1_DIR2 = 11, ID_OP1_DIR3 = 12,
            ID_OP1_IND1 = 13, ID_OP1_IND2 = 14, ID_OP1_IND3 = 15,
        ID_OP2_DIR1 = 16, ID_OP2_DIR2 = 17, ID_OP2_DIR3 = 18,
            ID_OP2_IND1 = 19, ID_OP2_IND2 = 20, ID_OP2_IND3 = 21,
        ID_OP3_DIR1 = 22, ID_OP3_DIR2 = 23, ID_OP3_DIR3 = 24,
            ID_OP3_IND1 = 25, ID_OP3_IND2 = 26, ID_OP3_IND3 = 27,

        EX = 28, 

        ST_DIR1 = 29, ST_DIR2 = 30, ST_DIR3 = 31,
            ST_IND1 = 32, ST_IND2 = 33,

        STOP_OP1_DIR1 = 34, STOP_OP1_DIR2 = 35, STOP_OP1_DIR3 = 36,
            STOP_OP1_IND1 = 37, STOP_OP1_IND2 = 38, STOP_OP1_IND3 = 39,

        STOP_OP2_DIR1 = 40, STOP_OP2_DIR2 = 41, STOP_OP2_DIR3 = 42,
            STOP_OP2_IND1 = 43, STOP_OP2_IND2 = 44, STOP_OP2_IND3 = 45,

        STOP_OP3_DIR1 = 46, STOP_OP3_DIR2 = 47, STOP_OP3_DIR3 = 48,
            STOP_OP3_IND1 = 49, STOP_OP3_IND2 = 50, STOP_OP3_IND3 = 51,

        STOP_OP1_DISP = 52, STOP_OP2_DISP = 53, STOP_OP3_DISP = 54,

        DONE = 55,

        OUTPUT = 56,

        IN_LOOP = 57,

        BRANCH = 58, JUMP = 59,

        MOV_LOOP = 60
    ;

    localparam // opcodes
        MOV = 4'b0000,
        ADD = 4'b0001,
        SUB = 4'b0010,
        MUL = 4'b0011,
        DIV = 4'b0100,
        BEQ = 4'b0101, //

        IN = 4'b0111,
        OUT = 4'b1000,
       
        STOP = 4'b1111
    ;

    reg [5:0] state, next_state;
    reg [DATA_HIGH:0] out_next;

    wire [3:0] opcode;
    wire op1_ind, op2_ind, op3_ind;
    wire [2:0] op1_addr, op2_addr, op3_addr;
    wire [15:0] c;

    assign c = ir_out[31:16];
    assign opcode = ir_out[15:12];
    assign op1_ind = ir_out[11];
    assign op1_addr = ir_out[10:8];
    assign op2_ind = ir_out[7];
    assign op2_addr = ir_out[6:4];
    assign op3_ind = ir_out[3];
    assign op3_addr = ir_out[2:0];

    assign test = c;
    assign test_state = state;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            state <= START;
            out <= 0;
        end
        else begin
            state <= next_state;
            out <= out_next;
        end
    end

    always @(*) begin

        {pc_cl, pc_ld, pc_inc, pc_dec, pc_sr, pc_ir, pc_sl, pc_il} = 8'b0;
        {sp_cl, sp_ld, sp_inc, sp_dec, sp_sr, sp_ir, sp_sl, sp_il} = 8'b0;
        {ir_cl, ir_ld, ir_inc, ir_dec, ir_sr, ir_ir, ir_sl, ir_il} = 8'b0;
        {mar_cl, mar_ld, mar_inc, mar_dec, mar_sr, mar_ir, mar_sl, mar_il} = 8'b0;
        {mdr_cl, mdr_ld, mdr_inc, mdr_dec, mdr_sr, mdr_ir, mdr_sl, mdr_il} = 8'b0;
        {acc_cl, acc_ld, acc_inc, acc_dec, acc_sr, acc_ir, acc_sl, acc_il} = 8'b0;

        ///////////////

        {src_cl, src_ld, src_inc, src_dec, src_sr, src_ir, src_sl, src_il} = 8'b0;
        {dst_cl, dst_ld, dst_inc, dst_dec, dst_sr, dst_ir, dst_sl, dst_il} = 8'b0;
        {cnt_cl, cnt_ld, cnt_inc, cnt_dec, cnt_sr, cnt_ir, cnt_sl, cnt_il} = 8'b0;

	    //////////////

        we = 1'b0;

        pc_in = 0;
        sp_in = 0;
        mar_in = 0;
        ir_in = 0;
        acc_in = 0;
        data = 0;
        status = 0;

        alu_a = mdr_out;
        alu_b = acc_out;
        alu_oc = 3'b0;

        next_state = state;
        out_next = out;

        case (state)
            START: begin
                pc_ld = 1'b1;
                pc_in = {{(ADDR_WIDTH - 4){1'b0}}, 4'h8};
                sp_ld = 1'b1;
                sp_in = {ADDR_WIDTH{1'b1}};
                next_state = IF1;
            end

            IF1: begin // mar <= pc; pc <= pc + 1;
                mar_in = pc;
                mar_ld = 1'b1;
                pc_inc = 1'b1;
                next_state = IF2;
            end

            IF2: begin // stall
                next_state = IF3;
            end

            IF3: begin // mdr <= mem[mar];
                mdr_ld = 1'b1;
                next_state = IF4;
            end

            IF4: begin // ir[15:0] <= mdr;
                ir_ld = 1'b1;
                src_ld = 1'b1;
                dst_ld = 1'b1;
                ir_in = mdr_out;
                next_state = ID;
            end

            // citanje druge reci

            IF5: begin // mar <= pc; pc <= pc + 1;
                mar_ld = 1'b1;
                mar_in = pc;
                pc_inc = 1'b1;
                next_state = IF6;
            end

            IF6: begin // stall
                next_state = IF7;
            end

            IF7: begin // mdr <= mem[mar];
                mdr_ld = 1'b1;
                next_state = IF8;
            end

            IF8: begin // ir[31:16] <= mdr;
                ir_ld = 1'b1;
                cnt_ld = 1'b1;
                ir_in = {mdr_out, ir_out[15:0]};
                case (opcode)
                    MOV: begin
                        if ({op3_ind, op3_addr} == 4'b1000) begin
                            next_state = ST_DIR1;
                        end
                        else if ({op3_ind, op3_addr} == 4'b1111) begin
                            next_state = ID_OP2_DIR1;
                        end
                    end
                    BEQ: begin
                        next_state = ID_OP1_DIR1;
                    end
                    default: 
                        next_state = IF1;
                endcase
                // vec je dekodovana instrukcija, ide na izvrsavanje, verovatno ovde case za operacije ako se bude koristilo ovo
            end

            //

            ID: begin // ako je nesto indirektno da se dohvati to iz memorije
                case (opcode) 
                    MOV: begin
                        if ({op3_ind, op3_addr} == 4'b0000) begin
                            next_state = ID_OP2_DIR1;
                        end
                        else if ({op3_ind, op3_addr} == 4'b1000) begin
                            next_state = IF5;
                        end
                        else if ({op3_ind, op3_addr} == 4'b1111) begin
                            next_state = IF5;
                        end
                        else begin
                            next_state = IF1;
                        end
                    end
                    ADD, SUB, MUL, DIV: begin
                        next_state = ID_OP3_DIR1;
                    end
                    //
                    BEQ: begin
                        if ({op3_ind, op3_addr} == 4'b1000) begin
                            next_state = IF5;
                        end
                        else begin
                            next_state = IF1;
                        end
                    end
                    //
                    IN: begin
                        next_state = ST_DIR1; // smestam na op1
                    end
                    OUT: begin
                        next_state = ID_OP1_DIR1; // uzimam op1
                    end
                    STOP: begin
                        next_state = STOP_OP1_DIR1;
                    end
                    default:
                        next_state = IF1;
                endcase
            end

            // op3

            ID_OP3_DIR1: begin // mar <= op3_addr
                mar_ld = 1'b1;
                mar_in = op3_addr;
                next_state = ID_OP3_DIR2;
            end

            ID_OP3_DIR2: begin // stall
                next_state = ID_OP3_DIR3;
            end

            ID_OP3_DIR3: begin // mdr <= mem[mar]
                mdr_ld = 1'b1;

                if (op3_ind == 1'b1) begin
                    next_state = ID_OP3_IND1;
                end
                else begin
                    next_state = ID_OP2_DIR1; // gotov, idem po sledeci
                end
            end

            ID_OP3_IND1: begin // mar <= mdr_out
                mar_ld = 1'b1;
                mar_in = mdr_out;
                next_state = ID_OP3_IND2;
            end

            ID_OP3_IND2: begin // stall
                next_state = ID_OP3_IND3;
            end

            ID_OP3_IND3: begin // mdr <= mem[mar]
                mdr_ld = 1'b1;
                next_state = ID_OP2_DIR1; // gotov, idem po sledeci
            end

            // op2

            ID_OP2_DIR1: begin // mar <= op2_addr
                if ({op2_ind, op2_addr} == 4'b0000 && opcode == BEQ) begin
                    next_state = BRANCH;
                end

                else begin
                    acc_ld = 1'b1;
                    acc_in = mdr_out; // prethodni ide u akumulator da ga ne pregazi

                    mar_ld = 1'b1;
                    if ({op3_ind, op3_addr} == 4'b1111) begin
                        mar_in = src_out;
                    end
                    else begin
                        mar_in = op2_addr;
                    end

                    next_state = ID_OP2_DIR2;
                end                
            end

            ID_OP2_DIR2: begin // stall
                next_state = ID_OP2_DIR3;
            end

            ID_OP2_DIR3: begin // mdr <= mem[mar]
                mdr_ld = 1'b1;

                if (op2_ind == 1'b1) begin
                    next_state = ID_OP2_IND1;
                end

                else begin
                    case (opcode)
                        MOV: begin
                            next_state = ST_DIR1; // idem po adresu gde se smesta ovo
                        end
                        ADD, SUB, MUL, DIV: begin // op3 i op2 idu na alu da se izracunaju
                            next_state = EX; // ovde nije pokupljena target adresa jos uvek nego to mora posle
                        end  
                        BEQ: begin
                            next_state = BRANCH;
                        end                       
                        default: begin // random greska
                            next_state = IF1;
                        end
                    endcase
                end
            end

            ID_OP2_IND1: begin // mar <= mdr_out
                mar_ld = 1'b1;
                mar_in = mdr_out;
                next_state = ID_OP3_IND2;
            end

            ID_OP2_IND2: begin // stall
                next_state = ID_OP2_IND3;
            end

            ID_OP2_IND3: begin // mdr <= mem[mar]
                mdr_ld = 1'b1;
                case (opcode)
                    MOV: begin
                        next_state = ST_DIR1; // idem po adresu gde se smesta ovo
                    end
                    ADD, SUB, MUL, DIV: begin // op3 i op2 idu na alu da se izracunaju
                        next_state = EX; // ovde nije pokupljena target adresa jos uvek nego to mora posle
                    end    
                    BEQ: begin
                        next_state = BRANCH;
                    end                      
                    default: begin // random greska
                        next_state = IF1;
                    end
                endcase
            end

            //
            BRANCH: begin
                if ({op1_ind, op1_addr} == {op2_ind, op2_addr}) begin
                    next_state = JUMP;
                end
                else if (({op1_ind, op1_addr} == 4'b0000) && mdr_out == 0) begin
                    next_state = JUMP;
                end
                else if (({op2_ind, op2_addr} == 4'b0000) && acc_out == 0) begin
                    next_state = JUMP;
                end
                else if (mdr_out == acc_out) begin
                    next_state = JUMP;
                end
                else begin
                    next_state = IF1;
                end            
            end

            JUMP: begin
                pc_ld = 1'b1;
                pc_in = c;
                next_state = IF1;
            end

            //



            EX: begin
                alu_a = mdr_out; // op2
                alu_b = acc_out; // op3

                case (opcode)
                    ADD: alu_oc = 3'b000;
                    SUB: alu_oc = 3'b001;
                    MUL: alu_oc = 3'b010;
                    DIV: alu_oc = 3'b011;
                endcase

                acc_ld = 1'b1;
                acc_in = alu_out;

                next_state = ST_DIR1; // sad idem po adresu tek
            end

            // op1 - adresa na koju se smesta rezultat

            ST_DIR1: begin // mar <= op1_addr
                mar_ld = 1'b1;
                if (({op3_ind, op3_addr} == 4'b1111) && (opcode == MOV)) begin
                    mar_in = dst_out;
                end
                else begin                  
                    mar_in = op1_addr;
                end
                next_state = ST_DIR2;
            end

            ST_DIR2: begin // stall
                next_state = ST_DIR3;
            end

            ST_DIR3: begin 
                if (op1_ind == 1'b1) begin // mdr <= mem[mar]
                    mdr_ld = 1'b1;
                    next_state = ST_IND1;
                end

                else begin
                    we = 1'b1;

                    next_state = IF1;

                    case (opcode)
                        MOV: begin
                            if ({op3_ind, op3_addr} == 4'b1111) begin
                                next_state = MOV_LOOP;
                                cnt_dec = 1'b1;
                                src_inc = 1'b1;
                                dst_inc = 1'b1;
                            end
                            // if ({op3_ind, op3_addr} == 4'b1000) begin
                            //     data = c;
                            // end
                            // else
                            data = mdr_out;
                        end
                        ADD, SUB, MUL: begin // !! div ne radi tako pise
                            data = acc_out;
                        end
                        IN: begin
                            next_state = IN_LOOP;
                        end
                        default: begin // ovde div upadne
                            // nistaaaaaaaaaaa
                        end
                    endcase
                end
            end

            ////////////////

            MOV_LOOP: begin
                if (cnt_out == 0) begin
                    next_state = IF1;
                end
                else begin
                  next_state = ID_OP2_DIR1;
                end
            end

            ///////////////


            IN_LOOP: begin
                we = 1'b1;
                status = 1'b1;
                if (!control) begin
                   next_state = IN_LOOP;             
                end
                else begin                    
                    data = in;
                    next_state = IF1;
                end
            end

            ST_IND1: begin // mar <= mdr_out
                mar_ld = 1'b1;
                mar_in = mdr_out;
                next_state = ST_IND2;
            end

            ST_IND2: begin // bas jako proveriti ovo da li pise gde sta treba
                we = 1'b1;

                next_state = IF1;

                case (opcode)
                    MOV: begin
                        data = mdr_out;
                    end
                    ADD, SUB, MUL: begin // !! div ne radi tako pise
                        data = acc_out;
                    end
                    IN: begin
                        next_state = IN_LOOP;
                    end
                    default: begin // ovde div upadne
                        // nistaaaaaaaaaaa
                    end
                endcase

                
            end


            // op1 - dohvatanje vrednosti za out i beq

            ID_OP1_DIR1: begin // mar <= op1_addr
                if ({op1_ind, op1_addr} == 4'b0000 && opcode == BEQ) begin
                    next_state = ID_OP2_DIR1;
                end
                else begin
                    mar_ld = 1'b1;
                    mar_in = op1_addr;
                    next_state = ID_OP1_DIR2; 
                end             
            end

            ID_OP1_DIR2: begin // stall
                next_state = ID_OP1_DIR3;
            end

            ID_OP1_DIR3: begin // mdr <= mem[mar]
                mdr_ld = 1'b1;

                if (op1_ind == 1'b1) begin
                    next_state = ID_OP1_IND1;
                end
                else begin
                    case (opcode)
                        OUT: begin
                            next_state = OUTPUT;
                        end
                        BEQ: begin
                            next_state = ID_OP2_DIR1;
                        end                        
                    endcase
                end
            end

            ID_OP1_IND1: begin // mar <= mdr_out
                mar_ld = 1'b1;
                mar_in = mdr_out;
                next_state = ID_OP1_IND2;
            end

            ID_OP1_IND2: begin // stall
                next_state = ID_OP1_IND3;
            end

            ID_OP1_IND3: begin // mdr <= mem[mar]
                mdr_ld = 1'b1;
                case (opcode)
                    OUT: begin
                        next_state = OUTPUT;
                    end
                    BEQ: begin
                        next_state = ID_OP2_DIR1;
                    end                        
                endcase
            end


            // stop

            // op1
            STOP_OP1_DIR1: begin               

                if ({op1_ind, op1_addr} == 4'b0) begin
                    next_state = STOP_OP2_DIR1;
                end

                else begin
                    mar_ld = 1'b1; // mar <= op1_addr
                    mar_in = op1_addr;
                    next_state = STOP_OP1_DIR2;
                end                
            end

            STOP_OP1_DIR2: begin // stall
                next_state = STOP_OP1_DIR3;
            end

            STOP_OP1_DIR3: begin // mdr <= mem[mar]
                mdr_ld = 1'b1;

                if (op1_ind == 1'b1) begin
                    next_state = STOP_OP1_IND1;
                end
                else begin
                    next_state = STOP_OP1_DISP; // gotov, stampam
                end
            end

            STOP_OP1_IND1: begin // mar <= mdr_out
                mar_ld = 1'b1;
                mar_in = mdr_out;
                next_state = STOP_OP1_IND2;
            end

            STOP_OP1_IND2: begin // stall
                next_state = STOP_OP1_IND3;
            end

            STOP_OP1_IND3: begin // mdr <= mem[mar]
                mdr_ld = 1'b1;
                next_state = STOP_OP1_DISP; // gotov, stampam
            end

            STOP_OP1_DISP: begin
                out_next = mdr_out;
                next_state = STOP_OP2_DIR1;
            end

            // op2
            STOP_OP2_DIR1: begin  
                if ({op2_ind, op2_addr} == 4'b0) begin
                    next_state = STOP_OP3_DIR1;
                end

                else begin
                    mar_ld = 1'b1; // mar <= op2_addr
                    mar_in = op2_addr;
                    next_state = STOP_OP2_DIR2;
                end                
            end

            STOP_OP2_DIR2: begin // stall
                next_state = STOP_OP2_DIR3;
            end

            STOP_OP2_DIR3: begin // mdr <= mem[mar]
                mdr_ld = 1'b1;

                if (op3_ind == 1'b1) begin
                    next_state = STOP_OP2_IND1;
                end
                else begin
                    next_state = STOP_OP2_DISP; // gotov, stampam
                end
            end

            STOP_OP2_IND1: begin // mar <= mdr_out
                mar_ld = 1'b1;
                mar_in = mdr_out;
                next_state = STOP_OP2_IND2;
            end

            STOP_OP2_IND2: begin // stall
                next_state = STOP_OP2_IND3;
            end

            STOP_OP2_IND3: begin // mdr <= mem[mar]
                mdr_ld = 1'b1;
                next_state = STOP_OP2_DISP; // gotov, stampam
            end

            STOP_OP2_DISP: begin
                out_next = mdr_out;
                next_state = STOP_OP3_DIR1;
            end

            //op3
            STOP_OP3_DIR1: begin               

                if ({op3_ind, op3_addr} == 4'b0) begin
                    next_state = STOP_OP3_DIR1;
                end

                else begin
                    mar_ld = 1'b1; // mar <= op3_addr
                    mar_in = op3_addr;
                    next_state = STOP_OP3_DIR2;
                end                
            end

            STOP_OP3_DIR2: begin // stall
                next_state = STOP_OP3_DIR3;
            end

            STOP_OP3_DIR3: begin // mdr <= mem[mar]
                mdr_ld = 1'b1;

                if (op3_ind == 1'b1) begin
                    next_state = STOP_OP3_IND1;
                end
                else begin
                    next_state = STOP_OP3_DISP; // gotov, stampam
                end
            end

            STOP_OP3_IND1: begin // mar <= mdr_out
                mar_ld = 1'b1;
                mar_in = mdr_out;
                next_state = STOP_OP3_IND2;
            end

            STOP_OP3_IND2: begin // stall
                next_state = STOP_OP1_IND3;
            end

            STOP_OP3_IND3: begin // mdr <= mem[mar]
                mdr_ld = 1'b1;
                next_state = STOP_OP3_DISP; // gotov, stampam
            end

            STOP_OP3_DISP: begin
                out_next = mdr_out;
                next_state = DONE;
            end

            DONE: begin
                next_state = DONE;
            end

            OUTPUT: begin
                out_next = mdr_out;
                next_state = IF1;
            end

            default: begin
                next_state = IF1;
            end
        endcase
    end

    
endmodule