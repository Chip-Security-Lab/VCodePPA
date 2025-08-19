//SystemVerilog
module onehot_demux (
    input  wire        clk,               // System clock
    input  wire        rst_n,             // Active-low synchronous reset
    input  wire        data_in,           // Input data
    input  wire [3:0]  one_hot_sel,       // One-hot selection (only one bit active)
    output wire [3:0]  data_out           // Output channels
);

    // Stage 1: Input Register Stage
    reg        data_in_s1;
    reg [3:0]  sel_s1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_s1 <= 1'b0;
            sel_s1     <= 4'b0;
        end else begin
            data_in_s1 <= data_in;
            sel_s1     <= one_hot_sel;
        end
    end

    // Stage 2: Selection Decode Stage
    reg        data_in_s2;
    reg [3:0]  sel_s2;
    reg [3:0]  demux_s2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_s2 <= 1'b0;
            sel_s2     <= 4'b0;
            demux_s2   <= 4'b0;
        end else begin
            data_in_s2 <= data_in_s1;
            sel_s2     <= sel_s1;
            demux_s2   <= {4{data_in_s1}} & sel_s1;
        end
    end

    // Stage 3: Output Register Stage
    reg [3:0] data_out_s3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_s3 <= 4'b0;
        end else begin
            data_out_s3 <= demux_s2;
        end
    end

    // Final Output Assignment
    assign data_out = data_out_s3;

endmodule