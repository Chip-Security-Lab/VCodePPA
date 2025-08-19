//SystemVerilog
// Register file with dual reset - Top level module
module dual_reset_regfile #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 5,
    parameter NUM_REGS = 2**ADDR_WIDTH
)(
    input  wire                   clk,
    input  wire                   async_rst_n,
    input  wire                   sync_rst,
    input  wire                   write_en,
    input  wire [ADDR_WIDTH-1:0]  write_addr,
    input  wire [DATA_WIDTH-1:0]  write_data,
    input  wire [ADDR_WIDTH-1:0]  read_addr,
    output wire [DATA_WIDTH-1:0]  read_data
);

    // Internal signals
    wire [DATA_WIDTH-1:0] reg_array [0:NUM_REGS-1];
    wire reset_active;

    // Reset control module
    reset_control #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reset_ctrl (
        .clk(clk),
        .async_rst_n(async_rst_n),
        .sync_rst(sync_rst),
        .reset_active(reset_active)
    );

    // Register array module
    reg_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .NUM_REGS(NUM_REGS)
    ) reg_array_inst (
        .clk(clk),
        .async_rst_n(async_rst_n),
        .reset_active(reset_active),
        .write_en(write_en),
        .write_addr(write_addr),
        .write_data(write_data),
        .reg_array(reg_array)
    );

    // Read port module
    read_port #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) read_port_inst (
        .clk(clk),
        .async_rst_n(async_rst_n),
        .reset_active(reset_active),
        .read_addr(read_addr),
        .reg_array(reg_array),
        .read_data(read_data)
    );

endmodule

// Reset control module
module reset_control #(
    parameter DATA_WIDTH = 16
)(
    input  wire clk,
    input  wire async_rst_n,
    input  wire sync_rst,
    output wire reset_active
);

    // Reset logic
    assign reset_active = !async_rst_n || sync_rst;

endmodule

// Register array module
module reg_array #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 5,
    parameter NUM_REGS = 2**ADDR_WIDTH
)(
    input  wire                   clk,
    input  wire                   async_rst_n,
    input  wire                   reset_active,
    input  wire                   write_en,
    input  wire [ADDR_WIDTH-1:0]  write_addr,
    input  wire [DATA_WIDTH-1:0]  write_data,
    output reg  [DATA_WIDTH-1:0]  reg_array [0:NUM_REGS-1]
);

    integer i;

    // Asynchronous reset and write logic
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            for (i = 0; i < NUM_REGS; i = i + 1) begin
                reg_array[i] <= {DATA_WIDTH{1'b0}};
            end
        end
        else if (reset_active) begin
            for (i = 0; i < NUM_REGS; i = i + 1) begin
                reg_array[i] <= {DATA_WIDTH{1'b0}};
            end
        end
    end

    // Write operation
    always @(posedge clk) begin
        if (write_en) begin
            reg_array[write_addr] <= write_data;
        end
    end

endmodule

// Read port module
module read_port #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 5
)(
    input  wire                   clk,
    input  wire                   async_rst_n,
    input  wire                   reset_active,
    input  wire [ADDR_WIDTH-1:0]  read_addr,
    input  wire [DATA_WIDTH-1:0]  reg_array [0:2**ADDR_WIDTH-1],
    output reg  [DATA_WIDTH-1:0]  read_data
);

    // Read logic
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            read_data <= {DATA_WIDTH{1'b0}};
        end
        else if (reset_active) begin
            read_data <= {DATA_WIDTH{1'b0}};
        end
        else begin
            read_data <= reg_array[read_addr];
        end
    end

endmodule