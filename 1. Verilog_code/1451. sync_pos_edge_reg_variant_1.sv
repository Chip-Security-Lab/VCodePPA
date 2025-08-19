//SystemVerilog
module sync_pos_edge_reg_axi (
    // Global signals
    input wire aclk,
    input wire aresetn,
    
    // AXI4-Lite slave interface
    // Write address channel
    input wire [31:0] s_axil_awaddr,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // Write data channel
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // Write response channel
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // Read address channel
    input wire [31:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // Read data channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready,
    
    // Original data output (kept for compatibility)
    output wire [7:0] data_out
);

    // Internal registers
    reg [7:0] data_reg;
    reg [31:0] read_addr;
    
    // State machine states
    localparam IDLE = 2'b00;
    localparam WRITE = 2'b01;
    localparam READ = 2'b10;
    localparam RESP = 2'b11;
    
    reg [1:0] write_state;
    reg [1:0] read_state;
    
    // Constants
    localparam RESP_OKAY = 2'b00;
    localparam RESP_SLVERR = 2'b10;
    
    // Register mapping - address for data register
    localparam DATA_REG_ADDR = 32'h0000_0000;
    
    // Original output connection
    assign data_out = data_reg;
    
    // Combined state machine for both read and write channels
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            // Write channel reset
            write_state <= IDLE;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= RESP_OKAY;
            data_reg <= 8'b0;
            
            // Read channel reset
            read_state <= IDLE;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= RESP_OKAY;
            s_axil_rdata <= 32'h0000_0000;
            read_addr <= 32'h0000_0000;
        end 
        else begin
            // Write channel state machine
            case (write_state)
                IDLE: begin
                    s_axil_bresp <= RESP_OKAY;
                    
                    if (s_axil_awvalid && s_axil_wvalid) begin
                        s_axil_awready <= 1'b1;
                        s_axil_wready <= 1'b1;
                        write_state <= WRITE;
                    end
                end
                
                WRITE: begin
                    s_axil_awready <= 1'b0;
                    s_axil_wready <= 1'b0;
                    
                    // Process the write based on address
                    if (s_axil_awaddr == DATA_REG_ADDR) begin
                        if (s_axil_wstrb[0])
                            data_reg <= s_axil_wdata[7:0];
                    end else begin
                        s_axil_bresp <= RESP_SLVERR;
                    end
                    
                    s_axil_bvalid <= 1'b1;
                    write_state <= RESP;
                end
                
                RESP: begin
                    if (s_axil_bready) begin
                        s_axil_bvalid <= 1'b0;
                        write_state <= IDLE;
                    end
                end
                
                default: write_state <= IDLE;
            endcase
            
            // Read channel state machine
            case (read_state)
                IDLE: begin
                    s_axil_rresp <= RESP_OKAY;
                    
                    if (s_axil_arvalid) begin
                        read_addr <= s_axil_araddr;
                        s_axil_arready <= 1'b1;
                        read_state <= READ;
                    end
                end
                
                READ: begin
                    s_axil_arready <= 1'b0;
                    
                    // Prepare read data based on address
                    if (read_addr == DATA_REG_ADDR) begin
                        s_axil_rdata <= {24'h0, data_reg};
                    end else begin
                        s_axil_rdata <= 32'h0000_0000;
                        s_axil_rresp <= RESP_SLVERR;
                    end
                    
                    s_axil_rvalid <= 1'b1;
                    read_state <= RESP;
                end
                
                RESP: begin
                    if (s_axil_rready) begin
                        s_axil_rvalid <= 1'b0;
                        read_state <= IDLE;
                    end
                end
                
                default: read_state <= IDLE;
            endcase
        end
    end

endmodule