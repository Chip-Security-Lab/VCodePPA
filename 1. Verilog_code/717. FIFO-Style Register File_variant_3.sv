//SystemVerilog
// FIFO Memory Core Module
module fifo_memory_core #(
    parameter DATA_W = 16,
    parameter DEPTH = 8,
    parameter PTR_WIDTH = $clog2(DEPTH)
)(
    input  wire                clk,
    input  wire                rst,
    input  wire [PTR_WIDTH:0]  wr_addr,
    input  wire [PTR_WIDTH:0]  rd_addr,
    input  wire [DATA_W-1:0]   wr_data,
    input  wire                wr_en,
    output reg  [DATA_W-1:0]   rd_data
);
    reg [DATA_W-1:0] mem [0:DEPTH-1];
    
    always @(posedge clk) begin
        if (wr_en) begin
            mem[wr_addr[PTR_WIDTH-1:0]] <= wr_data;
        end
        rd_data <= mem[rd_addr[PTR_WIDTH-1:0]];
    end
endmodule

// FIFO Pointer Control Module
module fifo_pointer_ctrl #(
    parameter DEPTH = 8,
    parameter PTR_WIDTH = $clog2(DEPTH)
)(
    input  wire                clk,
    input  wire                rst,
    input  wire                push,
    input  wire                pop,
    input  wire                full,
    input  wire                empty,
    output reg  [PTR_WIDTH:0]  wr_ptr,
    output reg  [PTR_WIDTH:0]  rd_ptr
);
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end else begin
            if (push && !full) begin
                wr_ptr <= wr_ptr + 1;
            end
            if (pop && !empty) begin
                rd_ptr <= rd_ptr + 1;
            end
        end
    end
endmodule

// FIFO Status Module
module fifo_status #(
    parameter DEPTH = 8,
    parameter PTR_WIDTH = $clog2(DEPTH)
)(
    input  wire [PTR_WIDTH:0]  wr_ptr,
    input  wire [PTR_WIDTH:0]  rd_ptr,
    output wire                empty,
    output wire                full,
    output wire [PTR_WIDTH:0]  count
);
    assign empty = (wr_ptr == rd_ptr);
    assign full = (wr_ptr[PTR_WIDTH-1:0] == rd_ptr[PTR_WIDTH-1:0]) && 
                 (wr_ptr[PTR_WIDTH] != rd_ptr[PTR_WIDTH]);
    assign count = wr_ptr - rd_ptr;
endmodule

// Top-level FIFO Module
module fifo_regfile #(
    parameter DATA_W = 16,
    parameter DEPTH = 8,
    parameter PTR_WIDTH = $clog2(DEPTH)
)(
    input  wire                clk,
    input  wire                rst,
    input  wire                push,
    input  wire [DATA_W-1:0]   push_data,
    output wire                full,
    input  wire                pop,
    output reg  [DATA_W-1:0]   pop_data,
    output wire                empty,
    output wire [PTR_WIDTH:0]  count
);

    // Internal signals
    wire [PTR_WIDTH:0] wr_ptr;
    wire [PTR_WIDTH:0] rd_ptr;
    wire [PTR_WIDTH:0] wr_ptr_stage1;
    wire [PTR_WIDTH:0] rd_ptr_stage1;
    wire [DATA_W-1:0]  push_data_stage1;
    wire              push_stage1;
    wire              pop_stage1;
    wire              empty_stage1;
    wire              full_stage1;
    wire [PTR_WIDTH:0] count_stage1;

    // Pipeline registers
    reg [PTR_WIDTH:0] wr_ptr_reg;
    reg [PTR_WIDTH:0] rd_ptr_reg;
    reg [DATA_W-1:0]  push_data_reg;
    reg              push_reg;
    reg              pop_reg;

    // Pipeline stage 1
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr_reg <= 0;
            rd_ptr_reg <= 0;
            push_data_reg <= 0;
            push_reg <= 0;
            pop_reg <= 0;
        end else begin
            wr_ptr_reg <= wr_ptr;
            rd_ptr_reg <= rd_ptr;
            push_data_reg <= push_data;
            push_reg <= push;
            pop_reg <= pop;
        end
    end

    assign wr_ptr_stage1 = wr_ptr_reg;
    assign rd_ptr_stage1 = rd_ptr_reg;
    assign push_data_stage1 = push_data_reg;
    assign push_stage1 = push_reg;
    assign pop_stage1 = pop_reg;

    // Instantiate submodules
    fifo_memory_core #(
        .DATA_W(DATA_W),
        .DEPTH(DEPTH),
        .PTR_WIDTH(PTR_WIDTH)
    ) mem_core (
        .clk(clk),
        .rst(rst),
        .wr_addr(wr_ptr_stage1),
        .rd_addr(rd_ptr_stage1),
        .wr_data(push_data_stage1),
        .wr_en(push_stage1 && !full_stage1),
        .rd_data(pop_data)
    );

    fifo_pointer_ctrl #(
        .DEPTH(DEPTH),
        .PTR_WIDTH(PTR_WIDTH)
    ) ptr_ctrl (
        .clk(clk),
        .rst(rst),
        .push(push_stage1),
        .pop(pop_stage1),
        .full(full_stage1),
        .empty(empty_stage1),
        .wr_ptr(wr_ptr),
        .rd_ptr(rd_ptr)
    );

    fifo_status #(
        .DEPTH(DEPTH),
        .PTR_WIDTH(PTR_WIDTH)
    ) status (
        .wr_ptr(wr_ptr_stage1),
        .rd_ptr(rd_ptr_stage1),
        .empty(empty_stage1),
        .full(full_stage1),
        .count(count_stage1)
    );

    // Output assignments
    assign empty = empty_stage1;
    assign full = full_stage1;
    assign count = count_stage1;

endmodule