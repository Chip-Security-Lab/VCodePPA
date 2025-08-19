//SystemVerilog
module Matrix_XNOR_AXI4Lite (
    // Global signals
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    
    // AXI4-Lite write address channel
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    
    // AXI4-Lite write data channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    
    // AXI4-Lite write response channel
    output reg [1:0]   s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    
    // AXI4-Lite read address channel
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    
    // AXI4-Lite read data channel
    output reg [31:0]  s_axi_rdata,
    output reg [1:0]   s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready
);

    // Internal registers
    reg [3:0] row_reg;
    reg [3:0] col_reg;
    reg [7:0] result_reg;
    
    // Address map (word-aligned)
    localparam ADDR_INPUT  = 4'h0;  // Address 0x00: [7:4]=col, [3:0]=row
    localparam ADDR_OUTPUT = 4'h4;  // Address 0x04: [7:0]=result
    
    // AXI4-Lite response codes
    localparam RESP_OKAY = 2'b00;
    localparam RESP_ERROR = 2'b10;
    
    // One-hot encoding states for write state machine
    localparam [3:0] W_IDLE = 4'b0001;
    localparam [3:0] W_ADDR = 4'b0010;
    localparam [3:0] W_DATA = 4'b0100;
    localparam [3:0] W_RESP = 4'b1000;
    
    // One-hot encoding states for read state machine
    localparam [3:0] R_IDLE = 4'b0001;
    localparam [3:0] R_ADDR = 4'b0010;
    localparam [3:0] R_DATA = 4'b0100;
    localparam [3:0] R_RSV  = 4'b1000; // Reserved state (previously 'default')
    
    // State registers (one-hot encoded)
    reg [3:0] write_state;
    reg [3:0] read_state;
    
    // Compute the matrix result using the original logic
    wire [7:0] mat_res;
    assign mat_res = ~({row_reg, col_reg} ^ 8'h55);
    
    // Write state machine with one-hot encoding
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            write_state <= W_IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= RESP_OKAY;
            row_reg <= 4'h0;
            col_reg <= 4'h0;
        end else begin
            case (write_state)
                W_IDLE: begin
                    if (s_axi_awvalid) begin
                        s_axi_awready <= 1'b1;
                        write_state <= W_ADDR;
                    end
                end
                
                W_ADDR: begin
                    s_axi_awready <= 1'b0;
                    if (s_axi_wvalid) begin
                        s_axi_wready <= 1'b1;
                        
                        // Check address and handle write data
                        case (s_axi_awaddr[7:0])
                            ADDR_INPUT: begin
                                if (s_axi_wstrb[0]) begin
                                    row_reg <= s_axi_wdata[3:0];
                                    col_reg <= s_axi_wdata[7:4];
                                end
                                s_axi_bresp <= RESP_OKAY;
                            end
                            default: begin
                                s_axi_bresp <= RESP_ERROR;
                            end
                        endcase
                        
                        write_state <= W_DATA;
                    end
                end
                
                W_DATA: begin
                    s_axi_wready <= 1'b0;
                    s_axi_bvalid <= 1'b1;
                    write_state <= W_RESP;
                end
                
                W_RESP: begin
                    if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        write_state <= W_IDLE;
                    end
                end
                
                default: begin
                    write_state <= W_IDLE;
                end
            endcase
        end
    end
    
    // Read state machine with one-hot encoding
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            read_state <= R_IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= RESP_OKAY;
            s_axi_rdata <= 32'h0;
            result_reg <= 8'h0;
        end else begin
            // Update result register from the computation
            result_reg <= mat_res;
            
            case (read_state)
                R_IDLE: begin
                    if (s_axi_arvalid) begin
                        s_axi_arready <= 1'b1;
                        read_state <= R_ADDR;
                    end
                end
                
                R_ADDR: begin
                    s_axi_arready <= 1'b0;
                    
                    // Prepare read data based on address
                    case (s_axi_araddr[7:0])
                        ADDR_INPUT: begin
                            s_axi_rdata <= {24'h0, col_reg, row_reg};
                            s_axi_rresp <= RESP_OKAY;
                        end
                        ADDR_OUTPUT: begin
                            s_axi_rdata <= {24'h0, result_reg};
                            s_axi_rresp <= RESP_OKAY;
                        end
                        default: begin
                            s_axi_rdata <= 32'h0;
                            s_axi_rresp <= RESP_ERROR;
                        end
                    endcase
                    
                    s_axi_rvalid <= 1'b1;
                    read_state <= R_DATA;
                end
                
                R_DATA: begin
                    if (s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        read_state <= R_IDLE;
                    end
                end
                
                R_RSV: begin
                    read_state <= R_IDLE;
                end
                
                default: begin
                    read_state <= R_IDLE;
                end
            endcase
        end
    end

endmodule