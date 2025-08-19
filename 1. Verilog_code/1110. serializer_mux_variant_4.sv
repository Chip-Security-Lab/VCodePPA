//SystemVerilog
module serializer_mux (
    input wire clk,                // Clock signal
    input wire rst_n,              // Active-low reset
    input wire load,               // Load parallel data
    input wire [7:0] parallel_in,  // Parallel input data
    input wire start,              // Start serialization
    output wire serial_out,        // Serial output
    output wire valid_out          // Output valid signal
);

    // Stage 1: Latch load and input data
    reg load_stage1;
    reg [7:0] parallel_in_stage1;
    reg start_stage1;

    // Stage 2: Shift register and valid logic
    reg [7:0] shift_reg_stage2;
    reg [2:0] bit_cnt_stage2;
    reg valid_stage2;

    // Stage 3: Output register
    reg serial_out_stage3;
    reg valid_stage3;

    // Stage 1: Capture inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            load_stage1        <= 1'b0;
            parallel_in_stage1 <= 8'b0;
            start_stage1       <= 1'b0;
        end else begin
            load_stage1        <= load;
            parallel_in_stage1 <= parallel_in;
            start_stage1       <= start;
        end
    end

    // Stage 2: Shift register logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage2 <= 8'b0;
            bit_cnt_stage2   <= 3'd0;
            valid_stage2     <= 1'b0;
        end else begin
            if (load_stage1 && start_stage1) begin
                shift_reg_stage2 <= parallel_in_stage1;
                bit_cnt_stage2   <= 3'd7;
                valid_stage2     <= 1'b1;
            end else if (valid_stage2 && bit_cnt_stage2 != 3'd0) begin
                shift_reg_stage2 <= {shift_reg_stage2[6:0], 1'b0};
                bit_cnt_stage2   <= bit_cnt_stage2 - 3'd1;
                valid_stage2     <= 1'b1;
            end else if (valid_stage2 && bit_cnt_stage2 == 3'd0) begin
                shift_reg_stage2 <= {shift_reg_stage2[6:0], 1'b0};
                bit_cnt_stage2   <= 3'd0;
                valid_stage2     <= 1'b0;
            end else begin
                valid_stage2     <= 1'b0;
            end
        end
    end

    // Stage 3: Output register and valid signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            serial_out_stage3 <= 1'b0;
            valid_stage3      <= 1'b0;
        end else begin
            serial_out_stage3 <= shift_reg_stage2[7];
            valid_stage3      <= valid_stage2;
        end
    end

    assign serial_out = serial_out_stage3;
    assign valid_out  = valid_stage3;

endmodule