//SystemVerilog
module mem_mapped_reset_ctrl (
    // Global signals
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    
    // AXI4-Lite slave interface - Write Address Channel
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    
    // AXI4-Lite slave interface - Write Data Channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    
    // AXI4-Lite slave interface - Write Response Channel
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    
    // AXI4-Lite slave interface - Read Address Channel
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    
    // AXI4-Lite slave interface - Read Data Channel
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    
    // Reset outputs
    output reg  [7:0]  reset_outputs
);

    // Local parameters
    localparam ADDR_WRITE   = 2'b00;  // Address 0: Direct write
    localparam ADDR_SET     = 2'b01;  // Address 1: Set bits
    localparam ADDR_CLEAR   = 2'b10;  // Address 2: Clear bits
    
    // AXI4-Lite response codes
    localparam RESP_OKAY    = 2'b00;
    localparam RESP_SLVERR  = 2'b10;
    
    // State machine states - One-Hot Encoding
    localparam IDLE         = 4'b0001;
    localparam WRITE_DATA   = 4'b0010;
    localparam WRITE_RESP   = 4'b0100;
    localparam READ_DATA    = 4'b1000;
    
    // Internal registers
    reg [3:0] write_state;
    reg [3:0] read_state;
    reg [1:0] reg_addr;
    reg [7:0] write_data;
    reg       write_valid;

    // Write state machine
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (~s_axi_aresetn) begin
            write_state <= IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= RESP_OKAY;
            reg_addr <= 2'b00;
            write_data <= 8'h00;
            write_valid <= 1'b0;
        end else begin
            // Default assignments
            write_valid <= 1'b0;
            
            case (write_state)
                IDLE: begin
                    s_axi_awready <= 1'b1;
                    s_axi_wready <= 1'b1;
                    
                    if (s_axi_awvalid) begin
                        reg_addr <= s_axi_awaddr[3:2];  // Extract register address
                        s_axi_awready <= 1'b0;
                        
                        if (s_axi_wvalid) begin
                            // Both address and data available
                            write_data <= s_axi_wdata[7:0];
                            write_valid <= 1'b1;
                            s_axi_wready <= 1'b0;
                            s_axi_bresp <= RESP_OKAY;
                            s_axi_bvalid <= 1'b1;
                            write_state <= WRITE_RESP;
                        end else begin
                            // Address available but waiting for data
                            write_state <= WRITE_DATA;
                        end
                    end else if (s_axi_wvalid) begin
                        // Data available but waiting for address
                        s_axi_wready <= 1'b0;
                        write_state <= IDLE;
                    end
                end
                
                WRITE_DATA: begin
                    s_axi_wready <= 1'b1;
                    if (s_axi_wvalid) begin
                        write_data <= s_axi_wdata[7:0];
                        write_valid <= 1'b1;
                        s_axi_wready <= 1'b0;
                        s_axi_bresp <= RESP_OKAY;
                        s_axi_bvalid <= 1'b1;
                        write_state <= WRITE_RESP;
                    end
                end
                
                WRITE_RESP: begin
                    if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        s_axi_awready <= 1'b1;
                        s_axi_wready <= 1'b1;
                        write_state <= IDLE;
                    end
                end
                
                default: write_state <= IDLE;
            endcase
        end
    end

    // Read state machine
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (~s_axi_aresetn) begin
            read_state <= IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= RESP_OKAY;
            s_axi_rdata <= 32'h00000000;
        end else begin
            case (read_state)
                IDLE: begin
                    s_axi_arready <= 1'b1;
                    if (s_axi_arvalid) begin
                        s_axi_arready <= 1'b0;
                        s_axi_rdata <= {24'h000000, reset_outputs};
                        s_axi_rresp <= RESP_OKAY;
                        s_axi_rvalid <= 1'b1;
                        read_state <= READ_DATA;
                    end
                end
                
                READ_DATA: begin
                    if (s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        s_axi_arready <= 1'b1;
                        read_state <= IDLE;
                    end
                end
                
                default: read_state <= IDLE;
            endcase
        end
    end

    // Reset control logic
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (~s_axi_aresetn) begin
            reset_outputs <= 8'h00;
        end else if (write_valid) begin
            case (reg_addr)
                ADDR_WRITE: reset_outputs <= write_data;
                ADDR_SET:   reset_outputs <= reset_outputs | write_data;  // Set bits
                ADDR_CLEAR: reset_outputs <= reset_outputs & ~write_data; // Clear bits
                default:    reset_outputs <= reset_outputs;
            endcase
        end
    end

endmodule