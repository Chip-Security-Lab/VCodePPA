//SystemVerilog
module sync_arithmetic_right_shifter #(
    parameter DW = 32,  // Data width
    parameter SW = 5    // Shift width
)(
    input                  clk_i,
    input                  rst_i,
    input                  valid_i,
    input      [DW-1:0]    data_i,
    input      [SW-1:0]    shift_i,
    output                 ready_o,
    output reg             valid_o,
    output reg [DW-1:0]    data_o
);
    // Internal pipeline registers
    reg [DW-1:0] data_stage1, data_stage2;
    reg [SW-1:0] shift_stage1, shift_stage2;
    reg valid_stage1, valid_stage2;
    
    // Pipeline stage 1: Input registration
    always @(posedge clk_i) begin
        if (rst_i) begin
            data_stage1 <= 0;
            shift_stage1 <= 0;
            valid_stage1 <= 0;
        end else if (ready_o) begin
            data_stage1 <= data_i;
            shift_stage1 <= shift_i;
            valid_stage1 <= valid_i;
        end
    end
    
    // Pipeline stage 2: Partial shift (first half of bits)
    always @(posedge clk_i) begin
        if (rst_i) begin
            data_stage2 <= 0;
            shift_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            data_stage2 <= $signed(data_stage1) >>> (shift_stage1 >> 1);
            shift_stage2 <= shift_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 借位减法器实现
    wire [SW-1:0] half_shift;
    wire [SW:0] borrow;
    wire [SW-1:0] remaining_shift;
    
    assign half_shift = shift_stage2 >> 1;
    assign borrow[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < SW; i = i + 1) begin : gen_borrow_subtractor
            assign remaining_shift[i] = shift_stage2[i] ^ half_shift[i] ^ borrow[i];
            assign borrow[i+1] = (~shift_stage2[i] & half_shift[i]) | 
                                 (~shift_stage2[i] & borrow[i]) | 
                                 (half_shift[i] & borrow[i]);
        end
    endgenerate
    
    // Pipeline stage 3: Final shift (remaining bits)
    always @(posedge clk_i) begin
        if (rst_i) begin
            data_o <= 0;
            valid_o <= 0;
        end else begin
            data_o <= $signed(data_stage2) >>> remaining_shift;
            valid_o <= valid_stage2;
        end
    end
    
    // Ready signal - always ready when not stalled
    assign ready_o = 1'b1;  // Can be modified to implement backpressure if needed
    
endmodule