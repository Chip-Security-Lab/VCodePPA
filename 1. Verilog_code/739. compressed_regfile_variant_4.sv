//SystemVerilog
module compressed_regfile #(
    parameter PACKED_WIDTH = 16,
    parameter UNPACKED_WIDTH = 32
)(
    input clk,
    input rst,
    input wr_en,
    input valid_in,
    input [3:0] addr,
    input [PACKED_WIDTH-1:0] din,
    output [UNPACKED_WIDTH-1:0] dout,
    output valid_out
);

    // Storage array
    reg [PACKED_WIDTH-1:0] storage [0:15];
    
    // Pipeline stage 1 registers
    reg [PACKED_WIDTH-1:0] read_data_stage1;
    reg valid_stage1;
    reg [3:0] addr_stage1;
    
    // Pipeline stage 2 registers
    reg [UNPACKED_WIDTH-1:0] expanded_data_stage2;
    reg valid_stage2;

    // Combinational read logic
    wire [PACKED_WIDTH-1:0] read_data_comb;
    assign read_data_comb = storage[addr];

    // Combinational expansion logic
    wire [UNPACKED_WIDTH-1:0] expanded_data_comb;
    assign expanded_data_comb = {{(UNPACKED_WIDTH-PACKED_WIDTH){1'b0}}, read_data_stage1};

    // Sequential write logic
    always @(posedge clk) begin
        if (rst) begin
            valid_stage1 <= 1'b0;
        end
        else begin
            if (wr_en) storage[addr] <= din;
            read_data_stage1 <= read_data_comb;
            addr_stage1 <= addr;
            valid_stage1 <= valid_in;
        end
    end

    // Sequential expansion logic
    always @(posedge clk) begin
        if (rst) begin
            valid_stage2 <= 1'b0;
        end
        else begin
            expanded_data_stage2 <= expanded_data_comb;
            valid_stage2 <= valid_stage1;
        end
    end

    // Output assignments
    assign dout = expanded_data_stage2;
    assign valid_out = valid_stage2;

endmodule