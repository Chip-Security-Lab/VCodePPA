//SystemVerilog
module dual_reset_regfile #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 5,
    parameter NUM_REGS = 2**ADDR_WIDTH
)(
    input  wire                   clk,
    input  wire                   async_rst_n,  // Active-low asynchronous reset
    input  wire                   sync_rst,     // Active-high synchronous reset
    input  wire                   write_en,
    input  wire [ADDR_WIDTH-1:0]  write_addr,
    input  wire [DATA_WIDTH-1:0]  write_data,
    input  wire [ADDR_WIDTH-1:0]  read_addr,
    output wire [DATA_WIDTH-1:0]  read_data     // Now a wire, connected from internal register
);
    // Internal signals
    wire reset_active;
    reg [DATA_WIDTH-1:0] read_data_reg;
    
    // Register array
    reg [DATA_WIDTH-1:0] registers [0:NUM_REGS-1];

    // Buffer for high fanout signals
    wire clk_buf;
    wire async_rst_n_buf;
    wire sync_rst_buf;

    // Buffering high fanout signals
    assign clk_buf = clk;
    assign async_rst_n_buf = async_rst_n;
    assign sync_rst_buf = sync_rst;

    // Reset detection logic - improves timing by pre-computing reset condition
    assign reset_active = sync_rst_buf || !async_rst_n_buf;
    
    // Output assignment
    assign read_data = read_data_reg;
    
    // Instantiate the reset handler module for read data path
    dual_reset_register #(
        .WIDTH(DATA_WIDTH)
    ) read_data_handler (
        .clk(clk_buf),
        .async_rst_n(async_rst_n_buf),
        .sync_rst(sync_rst_buf),
        .data_in(registers[read_addr]),
        .data_out(read_data_reg)
    );
    
    // Write operation with optimized reset handling
    always @(posedge clk_buf or negedge async_rst_n_buf) begin
        if (!async_rst_n_buf) begin
            // Asynchronous reset
            reset_registers(1'b1);
        end
        else if (sync_rst_buf) begin
            // Synchronous reset
            reset_registers(1'b0);
        end
        else if (write_en) begin
            registers[write_addr] <= write_data;
        end
    end
    
    // Task to handle register reset (reduces code duplication)
    task reset_registers;
        input is_async;
        begin
            integer i;
            for (i = 0; i < NUM_REGS; i = i + 1) begin
                registers[i] <= {DATA_WIDTH{1'b0}};
            end
        end
    endtask
endmodule

// Reusable dual-reset register module
module dual_reset_register #(
    parameter WIDTH = 16
)(
    input  wire               clk,
    input  wire               async_rst_n,
    input  wire               sync_rst,
    input  wire [WIDTH-1:0]   data_in,
    output reg  [WIDTH-1:0]   data_out
);
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            data_out <= {WIDTH{1'b0}};
        end
        else if (sync_rst) begin
            data_out <= {WIDTH{1'b0}};
        end
        else begin
            data_out <= data_in;
        end
    end
endmodule