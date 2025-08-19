//SystemVerilog
module serializer_mux (
    input wire clk,                    // Clock signal
    input wire rst_n,                  // Active-low synchronous reset
    input wire load,                   // Load parallel data
    input wire [7:0] parallel_in,      // Parallel input data
    output wire serial_out,            // Serial output
    output wire valid_out              // Output valid signal
);

    // Stage 1: Capture input and initiate load/shift operation
    reg [7:0] shift_reg_stage1;
    reg load_stage1;
    reg [7:0] parallel_in_stage1;
    reg valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage1    <= 8'd0;
            load_stage1         <= 1'b0;
            parallel_in_stage1  <= 8'd0;
            valid_stage1        <= 1'b0;
        end else begin
            shift_reg_stage1    <= shift_reg_stage2_next;
            load_stage1         <= load;
            parallel_in_stage1  <= parallel_in;
            valid_stage1        <= load | valid_stage2;
        end
    end

    // Stage 2: Perform shift or load operation
    reg [7:0] shift_reg_stage2;
    reg valid_stage2;

    wire [7:0] shift_reg_stage2_next;
    assign shift_reg_stage2_next = (load_stage1) ? parallel_in_stage1 : {shift_reg_stage1[6:0], 1'b0};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_stage2 <= 8'd0;
            valid_stage2     <= 1'b0;
        end else begin
            shift_reg_stage2 <= shift_reg_stage2_next;
            valid_stage2     <= valid_stage1;
        end
    end

    // Stage 3: Output stage
    reg serial_out_stage3;
    reg valid_stage3;

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