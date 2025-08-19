//SystemVerilog
module list2array_pipelined #(
    parameter DW = 8,
    parameter MAX_LEN = 8
)(
    input                  clk,
    input                  rst_n,
    input  [DW-1:0]        node_data,
    input                  node_valid,
    output [DW*MAX_LEN-1:0] array_out,
    output [3:0]           length
);

    // Internal registers
    reg [DW-1:0]           node_data_stage1;
    reg                    node_valid_stage1;

    reg [3:0]              idx_stage2;
    reg [3:0]              length_stage2;
    reg [DW-1:0]           node_data_stage2;
    reg                    node_valid_stage2;

    reg [DW-1:0]           mem [0:MAX_LEN-1];
    reg [3:0]              idx_stage3;
    reg [3:0]              length_stage3;
    reg                    node_valid_stage3;

    reg [DW*MAX_LEN-1:0]   array_out_stage4;
    reg [3:0]              length_stage4;

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Stage 1 Reset
            node_data_stage1  <= {DW{1'b0}};
            node_valid_stage1 <= 1'b0;
            // Stage 2 Reset
            idx_stage2        <= 4'd0;
            length_stage2     <= 4'd0;
            node_data_stage2  <= {DW{1'b0}};
            node_valid_stage2 <= 1'b0;
            // Stage 3 Reset
            for (i = 0; i < MAX_LEN; i = i + 1)
                mem[i] <= {DW{1'b0}};
            idx_stage3        <= 4'd0;
            length_stage3     <= 4'd0;
            node_valid_stage3 <= 1'b0;
            // Stage 4 Reset
            array_out_stage4  <= {DW*MAX_LEN{1'b0}};
            length_stage4     <= 4'd0;
        end else begin
            // Stage 1: Input Capture
            node_data_stage1  <= node_data;
            node_valid_stage1 <= node_valid;

            // Stage 2: Index and Length Update
            if (node_valid_stage1) begin
                idx_stage2       <= (idx_stage2 == MAX_LEN-1) ? 4'd0 : idx_stage2 + 1'b1;
                if (length_stage2 < MAX_LEN)
                    length_stage2  <= length_stage2 + 1'b1;
                else
                    length_stage2  <= MAX_LEN;
                node_data_stage2  <= node_data_stage1;
                node_valid_stage2 <= 1'b1;
            end else begin
                idx_stage2        <= idx_stage2;
                length_stage2     <= length_stage2;
                node_data_stage2  <= node_data_stage2;
                node_valid_stage2 <= 1'b0;
            end

            // Stage 3: Memory Write
            idx_stage3        <= idx_stage2;
            length_stage3     <= length_stage2;
            node_valid_stage3 <= node_valid_stage2;
            if (node_valid_stage2) begin
                mem[idx_stage2] <= node_data_stage2;
            end

            // Stage 4: Output Registering
            for (i = 0; i < MAX_LEN; i = i + 1) begin
                array_out_stage4[i*DW +: DW] <= mem[i];
            end
            length_stage4 <= length_stage3;
        end
    end

    assign array_out = array_out_stage4;
    assign length    = length_stage4;

endmodule