//SystemVerilog
module bit_ops_ext (
    input wire clk,
    input wire rst_n,
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input wire [31:0] s_axil_awaddr,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // Write Data Channel
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // Write Response Channel
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // Read Address Channel
    input wire [31:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // Read Data Channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready
);

    // Internal storage registers
    reg [3:0] src1_reg;
    reg [3:0] src2_reg;
    reg [3:0] concat_temp;
    reg [3:0] reverse_temp;
    reg [3:0] concat;
    reg [3:0] reverse;
    
    // Register addresses
    localparam ADDR_SRC1    = 4'h0;
    localparam ADDR_SRC2    = 4'h4;
    localparam ADDR_CONCAT  = 4'h8;
    localparam ADDR_REVERSE = 4'hC;
    
    // AXI FSM states
    typedef enum logic [1:0] {
        IDLE,
        ADDR_PHASE,
        DATA_PHASE,
        RESP_PHASE
    } axi_state_t;
    
    reg [1:0] write_state;
    reg [1:0] read_state;
    reg [31:0] read_addr;
    reg [31:0] write_addr;
    
    // Write channel FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_state <= IDLE;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
            write_addr <= 32'h0;
            src1_reg <= 4'b0;
            src2_reg <= 4'b0;
        end else begin
            case (write_state)
                IDLE: begin
                    s_axil_bvalid <= 1'b0;
                    if (s_axil_awvalid) begin
                        s_axil_awready <= 1'b1;
                        write_addr <= s_axil_awaddr;
                        write_state <= ADDR_PHASE;
                    end
                end
                
                ADDR_PHASE: begin
                    s_axil_awready <= 1'b0;
                    if (s_axil_wvalid) begin
                        s_axil_wready <= 1'b1;
                        
                        // Handle register writes
                        case (write_addr[3:0])
                            ADDR_SRC1: begin
                                if (s_axil_wstrb[0])
                                    src1_reg <= s_axil_wdata[3:0];
                            end
                            
                            ADDR_SRC2: begin
                                if (s_axil_wstrb[0])
                                    src2_reg <= s_axil_wdata[3:0];
                            end
                            
                            default: begin
                                // Invalid address, return error
                                s_axil_bresp <= 2'b10; // SLVERR
                            end
                        endcase
                        
                        write_state <= DATA_PHASE;
                    end
                end
                
                DATA_PHASE: begin
                    s_axil_wready <= 1'b0;
                    s_axil_bvalid <= 1'b1;
                    write_state <= RESP_PHASE;
                end
                
                RESP_PHASE: begin
                    if (s_axil_bready) begin
                        s_axil_bvalid <= 1'b0;
                        s_axil_bresp <= 2'b00; // OKAY
                        write_state <= IDLE;
                    end
                end
            endcase
        end
    end
    
    // Read channel FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_state <= IDLE;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= 2'b00;
            s_axil_rdata <= 32'h0;
            read_addr <= 32'h0;
        end else begin
            case (read_state)
                IDLE: begin
                    if (s_axil_arvalid) begin
                        s_axil_arready <= 1'b1;
                        read_addr <= s_axil_araddr;
                        read_state <= ADDR_PHASE;
                    end
                end
                
                ADDR_PHASE: begin
                    s_axil_arready <= 1'b0;
                    s_axil_rvalid <= 1'b1;
                    
                    // Handle register reads
                    case (read_addr[3:0])
                        ADDR_SRC1: begin
                            s_axil_rdata <= {28'h0, src1_reg};
                            s_axil_rresp <= 2'b00; // OKAY
                        end
                        
                        ADDR_SRC2: begin
                            s_axil_rdata <= {28'h0, src2_reg};
                            s_axil_rresp <= 2'b00; // OKAY
                        end
                        
                        ADDR_CONCAT: begin
                            s_axil_rdata <= {28'h0, concat};
                            s_axil_rresp <= 2'b00; // OKAY
                        end
                        
                        ADDR_REVERSE: begin
                            s_axil_rdata <= {28'h0, reverse};
                            s_axil_rresp <= 2'b00; // OKAY
                        end
                        
                        default: begin
                            s_axil_rdata <= 32'h0;
                            s_axil_rresp <= 2'b10; // SLVERR
                        end
                    endcase
                    
                    read_state <= DATA_PHASE;
                end
                
                DATA_PHASE: begin
                    if (s_axil_rready) begin
                        s_axil_rvalid <= 1'b0;
                        read_state <= IDLE;
                    end
                end
                
                default: read_state <= IDLE;
            endcase
        end
    end
    
    // Processing stage - retained from original design
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            concat_temp <= 4'b0;
            reverse_temp <= 4'b0;
        end else begin
            concat_temp <= {src1_reg[1:0], src2_reg[1:0]};
            reverse_temp <= {src1_reg[0], src1_reg[1], src1_reg[2], src1_reg[3]};
        end
    end
    
    // Output registration stage - retained from original design
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            concat <= 4'b0;
            reverse <= 4'b0;
        end else begin
            concat <= concat_temp;
            reverse <= reverse_temp;
        end
    end

endmodule