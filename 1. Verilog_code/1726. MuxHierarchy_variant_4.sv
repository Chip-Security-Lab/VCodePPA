//SystemVerilog
module MuxHierarchy #(parameter W=4) (
    input [7:0][W-1:0] group,
    input [2:0] addr,
    output reg [W-1:0] data
);

    // Internal signals
    reg [3:0][W-1:0] stage1_data;
    reg [1:0][W-1:0] stage2_data;
    reg [1:0] stage1_sel;
    reg stage2_sel;

    // Combined always block for all stages
    always @(*) begin
        // Stage 1: Select between upper and lower 4 groups
        stage1_sel = addr[2];
        stage1_data = stage1_sel ? group[7:4] : group[3:0];

        // Stage 2: Select between remaining 2 groups
        stage2_sel = addr[1];
        stage2_data = stage2_sel ? stage1_data[3:2] : stage1_data[1:0];

        // Final stage: Select final data
        data = stage2_data[addr[0]];
    end

endmodule