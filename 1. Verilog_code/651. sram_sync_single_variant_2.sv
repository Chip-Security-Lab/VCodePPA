//SystemVerilog
module sram_sync_single #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter DEPTH = 16
)(
    input clk,
    input rst_n,
    input cs,
    input we,
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] din,
    input [DATA_WIDTH-1:0] sub_value,  // Added input for subtraction
    output reg [DATA_WIDTH-1:0] dout,
    output reg [DATA_WIDTH-1:0] diff   // Added output for subtraction result
);

reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
reg [DATA_WIDTH-1:0] next_dout;
reg [ADDR_WIDTH-1:0] addr_reg;

// Parallel prefix subtractor signals
reg [DATA_WIDTH-1:0] next_diff;
wire [DATA_WIDTH-1:0] borrow;
wire [DATA_WIDTH-1:0] borrow_propagate;
wire [DATA_WIDTH-1:0] borrow_generate;
wire [DATA_WIDTH-1:0] borrow_carry;

// Parallel prefix subtractor implementation
genvar i;
generate
    // Generate and propagate signals
    for (i = 0; i < DATA_WIDTH; i = i + 1) begin : gen_pp
        assign borrow_generate[i] = ~din[i] & sub_value[i];
        assign borrow_propagate[i] = din[i] ~^ sub_value[i];
    end
    
    // First level of prefix computation
    wire [DATA_WIDTH-1:0] level1_generate;
    wire [DATA_WIDTH-1:0] level1_propagate;
    
    for (i = 0; i < DATA_WIDTH; i = i + 1) begin : level1
        if (i == 0) begin
            assign level1_generate[i] = borrow_generate[i];
            assign level1_propagate[i] = borrow_propagate[i];
        end else begin
            assign level1_generate[i] = borrow_generate[i] | (borrow_propagate[i] & borrow_generate[i-1]);
            assign level1_propagate[i] = borrow_propagate[i] & borrow_propagate[i-1];
        end
    end
    
    // Second level of prefix computation
    wire [DATA_WIDTH-1:0] level2_generate;
    wire [DATA_WIDTH-1:0] level2_propagate;
    
    for (i = 0; i < DATA_WIDTH; i = i + 1) begin : level2
        if (i < 2) begin
            assign level2_generate[i] = level1_generate[i];
            assign level2_propagate[i] = level1_propagate[i];
        end else begin
            assign level2_generate[i] = level1_generate[i] | (level1_propagate[i] & level1_generate[i-2]);
            assign level2_propagate[i] = level1_propagate[i] & level1_propagate[i-2];
        end
    end
    
    // Third level of prefix computation
    wire [DATA_WIDTH-1:0] level3_generate;
    wire [DATA_WIDTH-1:0] level3_propagate;
    
    for (i = 0; i < DATA_WIDTH; i = i + 1) begin : level3
        if (i < 4) begin
            assign level3_generate[i] = level2_generate[i];
            assign level3_propagate[i] = level2_propagate[i];
        end else begin
            assign level3_generate[i] = level2_generate[i] | (level2_propagate[i] & level2_generate[i-4]);
            assign level3_propagate[i] = level2_propagate[i] & level2_propagate[i-4];
        end
    end
    
    // Final borrow computation
    for (i = 0; i < DATA_WIDTH; i = i + 1) begin : borrow_comp
        if (i == 0)
            assign borrow[i] = 1'b0;
        else
            assign borrow[i] = level3_generate[i-1];
    end
    
    // Difference computation
    for (i = 0; i < DATA_WIDTH; i = i + 1) begin : diff_comp
        assign borrow_carry[i] = borrow[i];
    end
endgenerate

// Compute difference using parallel prefix results
wire [DATA_WIDTH-1:0] diff_wire;
assign diff_wire = din ^ sub_value ^ {borrow_carry[DATA_WIDTH-2:0], 1'b0};

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout <= {DATA_WIDTH{1'b0}};
        diff <= {DATA_WIDTH{1'b0}};
        addr_reg <= {ADDR_WIDTH{1'b0}};
        for (integer i=0; i<DEPTH; i=i+1) 
            mem[i] <= {DATA_WIDTH{1'b0}};
    end else begin
        addr_reg <= addr;
        if (cs) begin
            if (we) 
                mem[addr] <= din;
            next_dout <= mem[addr];
        end
        dout <= next_dout;
        next_diff <= diff_wire;
        diff <= next_diff;
    end
end

endmodule