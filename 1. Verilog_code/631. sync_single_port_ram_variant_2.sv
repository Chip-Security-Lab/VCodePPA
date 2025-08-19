//SystemVerilog
// State machine module
module ram_state_machine (
    input wire clk,
    input wire rst,
    input wire we,
    output reg [1:0] state
);

    localparam [1:0] IDLE = 2'b00,
                     WRITE = 2'b01,
                     READ = 2'b10;
    
    reg [1:0] next_state;
    
    // State transition logic
    always @(*) begin
        case(state)
            IDLE: next_state = we ? WRITE : READ;
            WRITE: next_state = IDLE;
            READ: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // State register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

endmodule

// Memory array module
module ram_memory_array #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire [1:0] state,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // Write operation
    always @(posedge clk) begin
        if (state == 2'b01) begin // WRITE state
            ram[addr] <= din;
        end
    end
    
    // Read operation
    always @(posedge clk) begin
        if (state == 2'b10) begin // READ state
            dout <= ram[addr];
        end
    end

endmodule

// Top level module
module sync_single_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);

    wire [1:0] state;
    wire [DATA_WIDTH-1:0] mem_dout;
    
    // State machine instance
    ram_state_machine state_machine (
        .clk(clk),
        .rst(rst),
        .we(we),
        .state(state)
    );
    
    // Memory array instance
    ram_memory_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) memory (
        .clk(clk),
        .state(state),
        .addr(addr),
        .din(din),
        .dout(mem_dout)
    );
    
    // Output register with reset
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end else begin
            dout <= mem_dout;
        end
    end

endmodule