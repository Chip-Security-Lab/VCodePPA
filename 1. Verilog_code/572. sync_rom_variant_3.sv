//SystemVerilog
module sync_rom_axi (
    // Clock and Reset
    input wire clk,
    input wire resetn,  // Active low reset
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input  wire [31:0] s_axil_awaddr,
    input  wire [2:0]  s_axil_awprot,
    input  wire        s_axil_awvalid,
    output reg         s_axil_awready,
    
    // Write Data Channel
    input  wire [31:0] s_axil_wdata,
    input  wire [3:0]  s_axil_wstrb,
    input  wire        s_axil_wvalid,
    output reg         s_axil_wready,
    
    // Write Response Channel
    output reg [1:0]   s_axil_bresp,
    output reg         s_axil_bvalid,
    input  wire        s_axil_bready,
    
    // Read Address Channel
    input  wire [31:0] s_axil_araddr,
    input  wire [2:0]  s_axil_arprot,
    input  wire        s_axil_arvalid,
    output reg         s_axil_arready,
    
    // Read Data Channel
    output reg [31:0]  s_axil_rdata,
    output reg [1:0]   s_axil_rresp,
    output reg         s_axil_rvalid,
    input  wire        s_axil_rready
);
    // Constants
    localparam RESP_OKAY = 2'b00;
    localparam RESP_SLVERR = 2'b10;
    
    // ROM storage
    (* ram_style = "block" *) reg [7:0] rom_memory [0:15];
    
    // Internal signals for ROM access
    reg [3:0] rom_addr;
    reg [7:0] rom_data;
    reg [7:0] data_out;
    
    // Pipeline registers
    reg [3:0] addr_reg;
    reg [7:0] data_reg;
    
    // State machine for AXI read transactions
    reg [1:0] read_state;
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;
    
    // ROM initialization
    initial begin
        rom_memory[0] = 8'h12; rom_memory[1] = 8'h34; rom_memory[2] = 8'h56; rom_memory[3] = 8'h78;
        rom_memory[4] = 8'h9A; rom_memory[5] = 8'hBC; rom_memory[6] = 8'hDE; rom_memory[7] = 8'hF0;
        rom_memory[8] = 8'h11; rom_memory[9] = 8'h22; rom_memory[10] = 8'h33; rom_memory[11] = 8'h44;
        rom_memory[12] = 8'h55; rom_memory[13] = 8'h66; rom_memory[14] = 8'h77; rom_memory[15] = 8'h88;
    end
    
    // AXI Read Transaction Handling
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= RESP_OKAY;
            s_axil_rdata <= 32'h0;
            read_state <= READ_IDLE;
            rom_addr <= 4'h0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    s_axil_arready <= 1'b1;  // Ready to accept address
                    if (s_axil_arvalid && s_axil_arready) begin
                        rom_addr <= s_axil_araddr[5:2]; // Use appropriate address bits
                        s_axil_arready <= 1'b0;
                        read_state <= READ_ADDR;
                    end
                end
                
                READ_ADDR: begin
                    // First pipeline stage - address register
                    addr_reg <= rom_addr;
                    read_state <= READ_DATA;
                end
                
                READ_DATA: begin
                    // Second pipeline stage - data register
                    data_reg <= rom_memory[addr_reg];
                    s_axil_rdata <= {24'h0, rom_memory[addr_reg]}; // Zero extend to 32 bits
                    s_axil_rresp <= RESP_OKAY;
                    s_axil_rvalid <= 1'b1;
                    
                    if (s_axil_rvalid && s_axil_rready) begin
                        s_axil_rvalid <= 1'b0;
                        s_axil_arready <= 1'b1;
                        read_state <= READ_IDLE;
                    end
                end
                
                default: read_state <= READ_IDLE;
            endcase
        end
    end
    
    // AXI Write Transaction Handling (ROM is read-only, so return error)
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= RESP_OKAY;
        end else begin
            // Accept write address and data, but return error since ROM is read-only
            if (!s_axil_awready && s_axil_awvalid) begin
                s_axil_awready <= 1'b1;
            end else if (s_axil_awready) begin
                s_axil_awready <= 1'b0;
            end
            
            if (!s_axil_wready && s_axil_wvalid) begin
                s_axil_wready <= 1'b1;
            end else if (s_axil_wready) begin
                s_axil_wready <= 1'b0;
            end
            
            if (!s_axil_bvalid && s_axil_awready && s_axil_wready) begin
                s_axil_bvalid <= 1'b1;
                s_axil_bresp <= RESP_SLVERR; // Slave error for write to ROM
            end else if (s_axil_bvalid && s_axil_bready) begin
                s_axil_bvalid <= 1'b0;
            end
        end
    end
    
    // Maintain original functionality to keep compatibility
    // These registers form the 3-stage pipeline of the original design
    always @(posedge clk) begin
        data_out <= data_reg;
    end
    
endmodule