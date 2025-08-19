//SystemVerilog
module param_equality_comparator #(
    parameter DATA_WIDTH = 16
)(
    input wire clock,
    input wire reset,
    input wire enable,
    input wire [DATA_WIDTH-1:0] data_in_a,
    input wire [DATA_WIDTH-1:0] data_in_b,
    output reg match_flag
);
    localparam CHUNK_SIZE = 4;
    localparam NUM_CHUNKS = (DATA_WIDTH + CHUNK_SIZE - 1) / CHUNK_SIZE;
    
    reg [NUM_CHUNKS-1:0] chunk_equal;
    reg is_equal_reg;
    
    always @(posedge clock) begin
        integer i, j;
        // Combinational comparison logic
        for (i = 0; i < NUM_CHUNKS; i = i + 1) begin
            chunk_equal[i] = 1'b1;
            for (j = 0; j < CHUNK_SIZE; j = j + 1) begin
                if ((i*CHUNK_SIZE + j) < DATA_WIDTH) begin
                    chunk_equal[i] = chunk_equal[i] & (data_in_a[i*CHUNK_SIZE + j] == data_in_b[i*CHUNK_SIZE + j]);
                end
            end
        end
        is_equal_reg = &chunk_equal;
        
        // Registered output with enable control
        case ({reset, enable})
            2'b10: match_flag <= 1'b0;
            2'b01: match_flag <= is_equal_reg;
            default: match_flag <= match_flag;
        endcase
    end
endmodule