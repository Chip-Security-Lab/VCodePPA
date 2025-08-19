//SystemVerilog
module shift_add_mult (
    input clk,
    input rst_n,
    input valid,
    output reg ready,
    input [7:0] mplier,
    input [7:0] mcand,
    output reg [15:0] result,
    output reg result_valid
);

    reg [15:0] accum_stage1, accum_stage2, accum_stage3;
    reg [7:0] mplier_stage1, mplier_stage2;
    reg [7:0] mcand_stage1, mcand_stage2;
    reg [2:0] state_stage1, state_stage2, state_stage3;
    reg [2:0] count_stage1, count_stage2;
    reg valid_stage1, valid_stage2;
    reg ready_stage1, ready_stage2;
    
    localparam IDLE = 3'd0;
    localparam CALC = 3'd1;
    localparam DONE = 3'd2;
    
    // Stage 1: Input and State Control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            ready_stage1 <= 1'b1;
            valid_stage1 <= 1'b0;
            mplier_stage1 <= 8'b0;
            mcand_stage1 <= 8'b0;
            count_stage1 <= 3'd0;
            accum_stage1 <= 16'b0;
        end else begin
            case (state_stage1)
                IDLE: begin
                    if (valid && ready_stage1) begin
                        state_stage1 <= CALC;
                        ready_stage1 <= 1'b0;
                        valid_stage1 <= 1'b1;
                        mplier_stage1 <= mplier;
                        mcand_stage1 <= mcand;
                        count_stage1 <= 3'd0;
                        accum_stage1 <= 16'b0;
                    end
                end
                
                CALC: begin
                    if (count_stage1 < 3'd8) begin
                        count_stage1 <= count_stage1 + 1'b1;
                    end else begin
                        state_stage1 <= DONE;
                        valid_stage1 <= 1'b0;
                    end
                end
                
                DONE: begin
                    if (!valid) begin
                        state_stage1 <= IDLE;
                        ready_stage1 <= 1'b1;
                    end
                end
                
                default: state_stage1 <= IDLE;
            endcase
        end
    end

    // Stage 2: Multiplication Calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= IDLE;
            ready_stage2 <= 1'b1;
            valid_stage2 <= 1'b0;
            mplier_stage2 <= 8'b0;
            mcand_stage2 <= 8'b0;
            count_stage2 <= 3'd0;
            accum_stage2 <= 16'b0;
        end else begin
            state_stage2 <= state_stage1;
            ready_stage2 <= ready_stage1;
            valid_stage2 <= valid_stage1;
            mplier_stage2 <= mplier_stage1;
            mcand_stage2 <= mcand_stage1;
            count_stage2 <= count_stage1;
            
            if (state_stage1 == CALC && count_stage1 < 3'd8) begin
                if (mplier_stage1[count_stage1]) begin
                    accum_stage2 <= accum_stage1 + (mcand_stage1 << count_stage1);
                end else begin
                    accum_stage2 <= accum_stage1;
                end
            end else begin
                accum_stage2 <= accum_stage1;
            end
        end
    end

    // Stage 3: Output Generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage3 <= IDLE;
            ready <= 1'b1;
            result <= 16'b0;
            result_valid <= 1'b0;
            accum_stage3 <= 16'b0;
        end else begin
            state_stage3 <= state_stage2;
            ready <= ready_stage2;
            accum_stage3 <= accum_stage2;
            
            if (state_stage2 == DONE) begin
                result <= accum_stage2;
                result_valid <= 1'b1;
            end else begin
                result_valid <= 1'b0;
            end
        end
    end

endmodule