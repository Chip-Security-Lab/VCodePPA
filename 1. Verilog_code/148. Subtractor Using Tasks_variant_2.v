module subtractor_axi_lite (
    // Clock and reset
    input wire aclk,
    input wire aresetn,
    
    // AXI4-Lite Write Address Channel
    input wire [31:0] s_axil_awaddr,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // AXI4-Lite Write Data Channel
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // AXI4-Lite Write Response Channel
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // AXI4-Lite Read Address Channel
    input wire [31:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // AXI4-Lite Read Data Channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready
);

    // Internal registers
    reg [7:0] reg_a;
    reg [7:0] reg_b;
    reg [7:0] reg_result;
    
    // Address decoding
    localparam ADDR_A = 4'h0;
    localparam ADDR_B = 4'h4;
    localparam ADDR_RESULT = 4'h8;
    
    // Write state machine - Binary encoding
    reg [2:0] write_state;
    localparam IDLE = 3'b000;
    localparam ADDR = 3'b001;
    localparam DATA = 3'b010;
    
    // Read state machine - Binary encoding
    reg [2:0] read_state;
    localparam R_IDLE = 3'b000;
    localparam R_ADDR = 3'b001;
    localparam R_DATA = 3'b010;
    
    // Write state machine
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            write_state <= IDLE;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
            reg_a <= 8'h0;
            reg_b <= 8'h0;
        end else begin
            case (write_state)
                IDLE: begin
                    s_axil_awready <= 1'b1;
                    s_axil_wready <= 1'b0;
                    s_axil_bvalid <= 1'b0;
                    
                    if (s_axil_awvalid) begin
                        write_state <= ADDR;
                        s_axil_awready <= 1'b0;
                    end
                end
                
                ADDR: begin
                    s_axil_wready <= 1'b1;
                    
                    if (s_axil_wvalid) begin
                        write_state <= DATA;
                        s_axil_wready <= 1'b0;
                        
                        case (s_axil_awaddr[3:0])
                            ADDR_A: begin
                                if (s_axil_wstrb[0]) reg_a <= s_axil_wdata[7:0];
                            end
                            ADDR_B: begin
                                if (s_axil_wstrb[0]) reg_b <= s_axil_wdata[7:0];
                            end
                            default: begin
                                s_axil_bresp <= 2'b10; // SLVERR
                            end
                        endcase
                    end
                end
                
                DATA: begin
                    s_axil_bvalid <= 1'b1;
                    
                    if (s_axil_bready) begin
                        write_state <= IDLE;
                        s_axil_bvalid <= 1'b0;
                        s_axil_bresp <= 2'b00; // OKAY
                    end
                end
                
                default: write_state <= IDLE;
            endcase
        end
    end
    
    // Read state machine
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            read_state <= R_IDLE;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= 2'b00;
            s_axil_rdata <= 32'h0;
        end else begin
            case (read_state)
                R_IDLE: begin
                    s_axil_arready <= 1'b1;
                    s_axil_rvalid <= 1'b0;
                    
                    if (s_axil_arvalid) begin
                        read_state <= R_ADDR;
                        s_axil_arready <= 1'b0;
                    end
                end
                
                R_ADDR: begin
                    read_state <= R_DATA;
                    
                    case (s_axil_araddr[3:0])
                        ADDR_A: s_axil_rdata <= {24'h0, reg_a};
                        ADDR_B: s_axil_rdata <= {24'h0, reg_b};
                        ADDR_RESULT: s_axil_rdata <= {24'h0, reg_result};
                        default: begin
                            s_axil_rdata <= 32'h0;
                            s_axil_rresp <= 2'b10; // SLVERR
                        end
                    endcase
                end
                
                R_DATA: begin
                    s_axil_rvalid <= 1'b1;
                    
                    if (s_axil_rready) begin
                        read_state <= R_IDLE;
                        s_axil_rvalid <= 1'b0;
                        s_axil_rresp <= 2'b00; // OKAY
                    end
                end
                
                default: read_state <= R_IDLE;
            endcase
        end
    end
    
    // Subtraction logic
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            reg_result <= 8'h0;
        end else begin
            reg_result <= reg_a - reg_b;
        end
    end

endmodule