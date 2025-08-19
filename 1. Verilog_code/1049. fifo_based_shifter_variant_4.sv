//SystemVerilog
//IEEE 1364-2005 Verilog
// Top-level module: Hierarchical FIFO-based Shifter
module fifo_based_shifter #(parameter DEPTH=8, WIDTH=16) (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [WIDTH-1:0]         data_in,
    input  wire                     push,
    input  wire                     pop,
    input  wire [2:0]               shift_amount,
    output wire [WIDTH-1:0]         data_out
);

    // Internal pointer signals
    wire [$clog2(DEPTH)-1:0]        rd_pointer;
    wire [$clog2(DEPTH)-1:0]        wr_pointer;

    // Internal FIFO memory array
    wire [WIDTH-1:0]                fifo_mem [0:DEPTH-1];

    // Write Pointer Control Submodule
    write_pointer_ctrl #(.DEPTH(DEPTH)) u_wr_ptr_ctrl (
        .clk        (clk),
        .rst_n      (rst_n),
        .push       (push),
        .wr_ptr     (wr_pointer)
    );

    // Read Pointer Control Submodule
    read_pointer_ctrl #(.DEPTH(DEPTH)) u_rd_ptr_ctrl (
        .clk        (clk),
        .rst_n      (rst_n),
        .pop        (pop),
        .rd_ptr     (rd_pointer)
    );

    // FIFO Memory Submodule
    fifo_memory #(.DEPTH(DEPTH), .WIDTH(WIDTH)) u_fifo_mem (
        .clk        (clk),
        .rst_n      (rst_n),
        .wr_en      (push),
        .wr_addr    (wr_pointer),
        .rd_addr    (get_shifted_addr(rd_pointer, shift_amount, DEPTH)),
        .data_in    (data_in),
        .data_out   (data_out),
        .mem_out    (fifo_mem)
    );

    // Function for conditional sum subtraction (3-bit)
    function [$clog2(DEPTH)-1:0] get_shifted_addr;
        input [$clog2(DEPTH)-1:0] rd_ptr;
        input [2:0] shift_amt;
        input integer depth;
        reg [2:0] sum;
        reg [2:0] carry;
        reg [2:0] temp_sum;
        reg [2:0] temp_carry;
        reg [$clog2(DEPTH)-1:0] addr_sum;
        begin
            // 3-bit conditional sum adder for (rd_ptr + shift_amt)
            // Stage 0
            temp_sum[0] = rd_ptr[0] ^ shift_amt[0];
            temp_carry[0] = rd_ptr[0] & shift_amt[0];
            // Stage 1
            temp_sum[1] = rd_ptr[1] ^ shift_amt[1] ^ temp_carry[0];
            temp_carry[1] = (rd_ptr[1] & shift_amt[1]) | (rd_ptr[1] & temp_carry[0]) | (shift_amt[1] & temp_carry[0]);
            // Stage 2
            temp_sum[2] = rd_ptr[2] ^ shift_amt[2] ^ temp_carry[1];
            temp_carry[2] = (rd_ptr[2] & shift_amt[2]) | (rd_ptr[2] & temp_carry[1]) | (shift_amt[2] & temp_carry[1]);
            // Compose the sum
            sum = {temp_sum[2], temp_sum[1], temp_sum[0]};
            // Conditional sum for modulo DEPTH
            addr_sum = sum % depth;
            get_shifted_addr = addr_sum;
        end
    endfunction

endmodule

//------------------------------------------------------------------------------
// Write Pointer Control Module
// Handles write pointer update logic for FIFO
//------------------------------------------------------------------------------
module write_pointer_ctrl #(parameter DEPTH=8) (
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   push,
    output reg  [$clog2(DEPTH)-1:0] wr_ptr
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (push) begin
            wr_ptr <= wr_ptr + 1'b1;
        end
    end
endmodule

//------------------------------------------------------------------------------
// Read Pointer Control Module
// Handles read pointer update logic for FIFO
//------------------------------------------------------------------------------
module read_pointer_ctrl #(parameter DEPTH=8) (
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   pop,
    output reg  [$clog2(DEPTH)-1:0] rd_ptr
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
        end else if (pop) begin
            rd_ptr <= rd_ptr + 1'b1;
        end
    end
endmodule

//------------------------------------------------------------------------------
// FIFO Memory Module
// Handles memory storage and shifted readout for FIFO
//------------------------------------------------------------------------------
module fifo_memory #(parameter DEPTH=8, WIDTH=16) (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     wr_en,
    input  wire [$clog2(DEPTH)-1:0] wr_addr,
    input  wire [$clog2(DEPTH)-1:0] rd_addr,
    input  wire [WIDTH-1:0]         data_in,
    output wire [WIDTH-1:0]         data_out,
    output wire [WIDTH-1:0]         mem_out [0:DEPTH-1]
);
    reg [WIDTH-1:0] memory [0:DEPTH-1];
    integer i;

    // Output the whole memory for debug or future expansion
    generate
        genvar gi;
        for (gi = 0; gi < DEPTH; gi = gi + 1) begin : mem_out_assign
            assign mem_out[gi] = memory[gi];
        end
    endgenerate

    // Write operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                memory[i] <= {WIDTH{1'b0}};
            end
        end else if (wr_en) begin
            memory[wr_addr] <= data_in;
        end
    end

    // Shifted read operation (combinational)
    assign data_out = memory[rd_addr];

endmodule