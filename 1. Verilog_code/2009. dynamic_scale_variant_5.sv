//SystemVerilog
module dynamic_scale #(
    parameter W = 24
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire [W-1:0]      data_in,
    input  wire [4:0]        shift_amt,
    output wire [W-1:0]      data_out
);

    // Pipeline Stage 1: Register inputs for timing clarity
    reg [W-1:0] data_in_stage1;
    reg [4:0]   shift_amt_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1    <= {W{1'b0}};
            shift_amt_stage1  <= 5'd0;
        end else begin
            data_in_stage1    <= data_in;
            shift_amt_stage1  <= shift_amt;
        end
    end

    // Pipeline Stage 2: Decode shift direction and magnitude
    reg         shift_left_stage2;
    reg [4:0]   shift_val_stage2;
    reg [W-1:0] data_in_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_left_stage2 <= 1'b0;
            shift_val_stage2  <= 5'd0;
            data_in_stage2    <= {W{1'b0}};
        end else begin
            if (shift_amt_stage1[4] && rst_n) begin
                shift_left_stage2 <= 1'b1;
                shift_val_stage2  <= (~shift_amt_stage1 + 1'b1);
            end else if (!shift_amt_stage1[4] && rst_n) begin
                shift_left_stage2 <= 1'b0;
                shift_val_stage2  <= shift_amt_stage1;
            end
            data_in_stage2    <= data_in_stage1;
        end
    end

    // Pipeline Stage 3: Perform shift operation (flattened if-else)
    reg [W-1:0] data_shifted_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_shifted_stage3 <= {W{1'b0}};
        end else if (shift_left_stage2 && rst_n) begin
            data_shifted_stage3 <= data_in_stage2 << shift_val_stage2;
        end else if (!shift_left_stage2 && rst_n) begin
            data_shifted_stage3 <= data_in_stage2 >> shift_val_stage2;
        end
    end

    // Output assignment from the final pipeline stage
    assign data_out = data_shifted_stage3;

endmodule