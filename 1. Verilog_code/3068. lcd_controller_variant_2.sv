//SystemVerilog
module lcd_controller(
    input wire clk, rst_n,
    input wire [7:0] data_in,
    input wire req,
    output reg ack,
    output reg rs, rw, e,
    output reg [7:0] data_out,
    output reg busy
);
    // State definitions
    localparam IDLE=3'd0, SETUP=3'd1, ENABLE=3'd2, HOLD=3'd3, DISABLE=3'd4;
    
    // Pipeline stage registers
    reg [2:0] state_stage1, state_stage2, state_stage3;
    reg [7:0] data_reg_stage1, data_reg_stage2, data_reg_stage3;
    reg rs_reg_stage1, rs_reg_stage2, rs_reg_stage3;
    reg [7:0] delay_cnt_stage1, delay_cnt_stage2, delay_cnt_stage3;
    reg req_reg_stage1, req_reg_stage2;
    reg req_stage1, req_stage2, req_stage3;
    
    // Pipeline control signals
    wire stage1_ack, stage2_ack, stage3_ack;
    wire stage1_req, stage2_req, stage3_req;
    
    // Optimized state transition logic
    wire [2:0] next_state_stage1;
    wire [2:0] state_compare = state_stage1;
    wire [7:0] delay_compare = delay_cnt_stage1;
    
    assign next_state_stage1 = 
        (state_compare == IDLE && req) ? SETUP :
        (state_compare == SETUP && delay_compare >= 8'd5) ? ENABLE :
        (state_compare == ENABLE && delay_compare >= 8'd10) ? HOLD :
        (state_compare == HOLD && delay_compare >= 8'd20) ? DISABLE :
        (state_compare == DISABLE && delay_compare >= 8'd5) ? IDLE : state_compare;
    
    // Stage 1: Input stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            data_reg_stage1 <= 8'd0;
            rs_reg_stage1 <= 1'b0;
            delay_cnt_stage1 <= 8'd0;
            req_reg_stage1 <= 1'b0;
            req_stage1 <= 1'b0;
        end else if (stage1_ack) begin
            state_stage1 <= next_state_stage1;
            data_reg_stage1 <= (state_stage1 == IDLE && req) ? data_in : data_reg_stage1;
            rs_reg_stage1 <= (state_stage1 == IDLE && req) ? data_in[7] : rs_reg_stage1;
            delay_cnt_stage1 <= (state_stage1 != next_state_stage1) ? 8'd0 : delay_cnt_stage1 + 8'd1;
            req_reg_stage1 <= req;
            req_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Processing stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= IDLE;
            data_reg_stage2 <= 8'd0;
            rs_reg_stage2 <= 1'b0;
            delay_cnt_stage2 <= 8'd0;
            req_reg_stage2 <= 1'b0;
            req_stage2 <= 1'b0;
        end else if (stage2_ack && req_stage1) begin
            state_stage2 <= state_stage1;
            data_reg_stage2 <= data_reg_stage1;
            rs_reg_stage2 <= rs_reg_stage1;
            delay_cnt_stage2 <= delay_cnt_stage1;
            req_reg_stage2 <= req_reg_stage1;
            req_stage2 <= 1'b1;
        end
    end
    
    // Stage 3: Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage3 <= IDLE;
            data_reg_stage3 <= 8'd0;
            rs_reg_stage3 <= 1'b0;
            delay_cnt_stage3 <= 8'd0;
            req_stage3 <= 1'b0;
        end else if (stage3_ack && req_stage2) begin
            state_stage3 <= state_stage2;
            data_reg_stage3 <= data_reg_stage2;
            rs_reg_stage3 <= rs_reg_stage2;
            delay_cnt_stage3 <= delay_cnt_stage2;
            req_stage3 <= 1'b1;
        end
    end
    
    // Output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 1'b0;
            data_out <= 8'd0;
            rs <= 1'b0;
            rw <= 1'b0;
            e <= 1'b0;
            ack <= 1'b0;
        end else if (req_stage3) begin
            busy <= (state_stage3 != IDLE);
            data_out <= data_reg_stage3;
            rs <= rs_reg_stage3;
            rw <= 1'b0;
            e <= (state_stage3 == ENABLE || state_stage3 == HOLD);
            ack <= 1'b1;
        end else begin
            ack <= 1'b0;
        end
    end
    
    // Pipeline control logic
    assign stage1_ack = !req_stage1 || (req_stage2 && stage2_ack);
    assign stage2_ack = !req_stage2 || (req_stage3 && stage3_ack);
    assign stage3_ack = !req_stage3 || !busy;
    
endmodule