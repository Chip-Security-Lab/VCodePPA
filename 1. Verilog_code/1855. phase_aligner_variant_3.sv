//SystemVerilog
module phase_aligner #(parameter PHASES=4, DATA_W=8) (
    input clk, rst,
    input [DATA_W-1:0] phase_data_0,
    input [DATA_W-1:0] phase_data_1,
    input [DATA_W-1:0] phase_data_2,
    input [DATA_W-1:0] phase_data_3,
    output [DATA_W-1:0] aligned_data
);
    // Internal signals
    wire [DATA_W-1:0] xor_result;
    wire [DATA_W-1:0] sync_data [PHASES-1:0];
    reg [DATA_W-1:0] sync_reg [PHASES-1:0];
    reg [DATA_W-1:0] aligned_data_reg;
    
    // Phase data synchronization module
    phase_sync #(
        .PHASES(PHASES),
        .DATA_W(DATA_W)
    ) phase_sync_inst (
        .clk(clk),
        .rst(rst),
        .phase_data_0(phase_data_0),
        .phase_data_1(phase_data_1),
        .phase_data_2(phase_data_2),
        .phase_data_3(phase_data_3),
        .sync_reg(sync_reg)
    );
    
    // Combinational logic module
    phase_combinator #(
        .PHASES(PHASES),
        .DATA_W(DATA_W)
    ) phase_combinator_inst (
        .sync_data(sync_reg),
        .xor_result(xor_result)
    );
    
    // Output register
    output_register #(
        .DATA_W(DATA_W)
    ) output_register_inst (
        .clk(clk),
        .rst(rst),
        .data_in(xor_result),
        .data_out(aligned_data)
    );
endmodule

//SystemVerilog
module phase_sync #(parameter PHASES=4, DATA_W=8) (
    input clk, rst,
    input [DATA_W-1:0] phase_data_0,
    input [DATA_W-1:0] phase_data_1,
    input [DATA_W-1:0] phase_data_2,
    input [DATA_W-1:0] phase_data_3,
    output reg [DATA_W-1:0] sync_reg [PHASES-1:0]
);
    // Sequential logic for phase data synchronization
    integer i;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Parallel reset implementation
            for(i=0; i<PHASES; i=i+1)
                sync_reg[i] <= {DATA_W{1'b0}};
        end else begin
            // Explicit mapping improves readability and synthesis
            sync_reg[0] <= phase_data_1;
            sync_reg[1] <= phase_data_2;
            sync_reg[2] <= phase_data_3;
            sync_reg[3] <= phase_data_0;
        end
    end
endmodule

//SystemVerilog
module phase_combinator #(parameter PHASES=4, DATA_W=8) (
    input [DATA_W-1:0] sync_data [PHASES-1:0],
    output [DATA_W-1:0] xor_result
);
    // Pure combinational logic with optimized tree structure
    wire [DATA_W-1:0] xor_level1 [PHASES/2-1:0];
    
    // First level XOR operations
    genvar j;
    generate
        for (j=0; j<PHASES/2; j=j+1) begin : xor_level1_gen
            assign xor_level1[j] = sync_data[j*2] ^ sync_data[j*2+1];
        end
    endgenerate
    
    // Final XOR result with balanced tree structure
    assign xor_result = xor_level1[0] ^ xor_level1[1];
endmodule

//SystemVerilog
module output_register #(parameter DATA_W=8) (
    input clk, rst,
    input [DATA_W-1:0] data_in,
    output reg [DATA_W-1:0] data_out
);
    // Output pipeline register
    always @(posedge clk or posedge rst) begin
        if (rst)
            data_out <= {DATA_W{1'b0}};
        else
            data_out <= data_in;
    end
endmodule