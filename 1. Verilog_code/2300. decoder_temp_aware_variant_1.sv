//SystemVerilog
module decoder_temp_aware #(parameter THRESHOLD=85) (
    input  wire        clk,
    input  wire        rst_n,      // Reset signal (active low)
    input  wire        valid_in,   // Input valid signal
    input  wire [7:0]  temp,
    input  wire [3:0]  addr,
    output reg         valid_out,  // Output valid signal
    output reg  [15:0] decoded
);

    // Stage 1 registers
    reg [7:0]  temp_stage1;
    reg [3:0]  addr_stage1;
    reg        valid_stage1;
    reg        temp_above_threshold_stage1;

    // Stage 2 registers
    reg [3:0]  addr_stage2;
    reg        valid_stage2;
    reg        temp_above_threshold_stage2;
    reg [15:0] pre_decoded_stage2;

    // Pipeline Stage 1: Input Capture and Temperature Compare
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            temp_stage1 <= 8'h0;
            addr_stage1 <= 4'h0;
            valid_stage1 <= 1'b0;
            temp_above_threshold_stage1 <= 1'b0;
        end else begin
            temp_stage1 <= temp;
            addr_stage1 <= addr;
            valid_stage1 <= valid_in;
            temp_above_threshold_stage1 <= (temp > THRESHOLD);
        end
    end

    // Pipeline Stage 2: Decode Address and Apply Temperature Mask
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage2 <= 4'h0;
            valid_stage2 <= 1'b0;
            temp_above_threshold_stage2 <= 1'b0;
            pre_decoded_stage2 <= 16'h0;
        end else begin
            addr_stage2 <= addr_stage1;
            valid_stage2 <= valid_stage1;
            temp_above_threshold_stage2 <= temp_above_threshold_stage1;
            pre_decoded_stage2 <= (1'b1 << addr_stage1);
        end
    end

    // Pipeline Stage 3: Final Output with Temperature Condition Applied
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoded <= 16'h0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_stage2;
            if (temp_above_threshold_stage2)
                decoded <= pre_decoded_stage2 & 16'h00FF;
            else
                decoded <= pre_decoded_stage2;
        end
    end

endmodule