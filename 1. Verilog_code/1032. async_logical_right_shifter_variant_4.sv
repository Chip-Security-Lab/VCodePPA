//SystemVerilog
module async_logical_right_shifter #(
    parameter DATA_WIDTH = 16,
    parameter SHIFT_WIDTH = 4
)(
    input  wire                        clk,
    input  wire                        rst_n,
    input  wire [DATA_WIDTH-1:0]       in_data,
    input  wire [SHIFT_WIDTH-1:0]      shift_amount,
    output wire [DATA_WIDTH-1:0]       out_data
);

    ////////////////////////////////////////////////////////////////////////////////
    // Pipeline Stage 1: Input Capture
    ////////////////////////////////////////////////////////////////////////////////
    reg [DATA_WIDTH-1:0]   data_stage1;
    reg [SHIFT_WIDTH-1:0]  shift_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1  <= {DATA_WIDTH{1'b0}};
            shift_stage1 <= {SHIFT_WIDTH{1'b0}};
        end else begin
            data_stage1  <= in_data;
            shift_stage1 <= shift_amount;
        end
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Pipeline Stage 2: Shift Computation
    ////////////////////////////////////////////////////////////////////////////////
    reg [DATA_WIDTH-1:0]   shifted_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shifted_stage2 <= {DATA_WIDTH{1'b0}};
        end else begin
            shifted_stage2 <= data_stage1 >> shift_stage1;
        end
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Pipeline Stage 3: Output Register
    ////////////////////////////////////////////////////////////////////////////////
    reg [DATA_WIDTH-1:0]   out_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_stage3 <= {DATA_WIDTH{1'b0}};
        end else begin
            out_stage3 <= shifted_stage2;
        end
    end

    assign out_data = out_stage3;

endmodule