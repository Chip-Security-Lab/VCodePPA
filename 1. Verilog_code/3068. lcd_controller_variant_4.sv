//SystemVerilog
module lcd_controller(
    input wire clk, rst_n,
    input wire [7:0] data_in,
    input wire start_xfer,
    output reg rs, rw, e,
    output reg [7:0] data_out,
    output reg busy
);
    localparam IDLE=3'd0, SETUP=3'd1, ENABLE=3'd2, HOLD=3'd3, DISABLE=3'd4;
    reg [2:0] state_stage1, state_stage2, next_stage1;
    reg [7:0] data_reg_stage1, data_reg_stage2;
    reg rs_reg_stage1, rs_reg_stage2;
    reg [7:0] delay_cnt_stage1, delay_cnt_stage2;
    reg valid_stage1, valid_stage2;
    
    // Optimized signed multiplier
    wire [7:0] signed_data_in;
    wire [7:0] signed_data_reg;
    wire [15:0] mult_result;
    
    assign signed_data_in = {data_in[7], data_in[6:0]};
    assign signed_data_reg = {data_reg_stage1[7], data_reg_stage1[6:0]};
    
    // Booth multiplier implementation
    booth_multiplier #(.WIDTH(8)) booth_mult (
        .a(signed_data_in),
        .b(signed_data_reg),
        .result(mult_result)
    );
    
    // Stage 1: Input and Setup
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            data_reg_stage1 <= 8'd0;
            rs_reg_stage1 <= 1'b0;
            delay_cnt_stage1 <= 8'd0;
            valid_stage1 <= 1'b0;
        end else begin
            state_stage1 <= next_stage1;
            valid_stage1 <= (state_stage1 != IDLE) || start_xfer;
            
            if (state_stage1 == IDLE && start_xfer) begin
                data_reg_stage1 <= mult_result[7:0];
                rs_reg_stage1 <= mult_result[7];
            end
            
            if (state_stage1 != next_stage1)
                delay_cnt_stage1 <= 8'd0;
            else
                delay_cnt_stage1 <= delay_cnt_stage1 + 8'd1;
        end
    end
    
    // Stage 2: Processing and Output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= IDLE;
            data_reg_stage2 <= 8'd0;
            rs_reg_stage2 <= 1'b0;
            delay_cnt_stage2 <= 8'd0;
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                state_stage2 <= state_stage1;
                data_reg_stage2 <= data_reg_stage1;
                rs_reg_stage2 <= rs_reg_stage1;
                delay_cnt_stage2 <= delay_cnt_stage1;
                valid_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // Stage 1 Next State Logic
    always @(*) begin
        case (state_stage1)
            IDLE: next_stage1 = start_xfer ? SETUP : IDLE;
            SETUP: next_stage1 = (delay_cnt_stage1 >= 8'd5) ? ENABLE : SETUP;
            ENABLE: next_stage1 = (delay_cnt_stage1 >= 8'd10) ? HOLD : ENABLE;
            HOLD: next_stage1 = (delay_cnt_stage1 >= 8'd20) ? DISABLE : HOLD;
            DISABLE: next_stage1 = (delay_cnt_stage1 >= 8'd5) ? IDLE : DISABLE;
            default: next_stage1 = IDLE;
        endcase
    end
    
    // Output Logic
    always @(*) begin
        busy = valid_stage2;
        data_out = data_reg_stage2;
        rs = rs_reg_stage2;
        rw = 1'b0;
        e = (state_stage2 == ENABLE || state_stage2 == HOLD);
    end
endmodule

module booth_multiplier #(
    parameter WIDTH = 8
)(
    input wire signed [WIDTH-1:0] a,
    input wire signed [WIDTH-1:0] b,
    output reg signed [2*WIDTH-1:0] result
);
    reg signed [WIDTH:0] partial_product;
    reg signed [2*WIDTH-1:0] accumulator;
    integer i;
    
    always @(*) begin
        accumulator = 0;
        for (i = 0; i < WIDTH; i = i + 1) begin
            case ({b[i], (i > 0) ? b[i-1] : 1'b0})
                2'b01: partial_product = a;
                2'b10: partial_product = -a;
                default: partial_product = 0;
            endcase
            accumulator = accumulator + (partial_product << i);
        end
        result = accumulator;
    end
endmodule