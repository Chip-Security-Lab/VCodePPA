//SystemVerilog
module reset_pattern_gen(
    input wire s_axi_aclk,
    input wire s_axi_aresetn,
    
    // AXI4-Lite Write Address Channel
    input wire [31:0] s_axi_awaddr,
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    
    // AXI4-Lite Write Data Channel
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output reg s_axi_wready,
    
    // AXI4-Lite Write Response Channel
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    
    // AXI4-Lite Read Address Channel
    input wire [31:0] s_axi_araddr,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    
    // AXI4-Lite Read Data Channel
    output reg [31:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready,
    
    // Original module output
    output reg [7:0] reset_seq
);

    // Register address offsets (in bytes)
    localparam ADDR_TRIGGER = 4'h0;
    localparam ADDR_PATTERN = 4'h4;
    localparam ADDR_RESET_SEQ = 4'h8;
    
    // Internal registers
    reg [2:0] bit_pos;
    reg [2:0] bit_pos_next;
    reg trigger;
    reg [7:0] pattern;
    reg [7:0] reset_seq_next;
    
    // AXI4-Lite Write FSM states
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    reg [1:0] write_state;
    
    // AXI4-Lite Read FSM states
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;
    reg [1:0] read_state;
    
    // Registered address for write/read operations
    reg [31:0] axi_awaddr_reg;
    reg [31:0] axi_araddr_reg;
    
    // Write transaction handling
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            write_state <= WRITE_IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;
            axi_awaddr_reg <= 32'h0;
            trigger <= 1'b0;
            pattern <= 8'h0;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    if (s_axi_awvalid) begin
                        s_axi_awready <= 1'b1;
                        axi_awaddr_reg <= s_axi_awaddr;
                        write_state <= WRITE_ADDR;
                    end
                end
                
                WRITE_ADDR: begin
                    s_axi_awready <= 1'b0;
                    if (s_axi_wvalid) begin
                        s_axi_wready <= 1'b1;
                        write_state <= WRITE_DATA;
                    end
                end
                
                WRITE_DATA: begin
                    s_axi_wready <= 1'b0;
                    // Handle register writes based on address
                    if (s_axi_wstrb[0]) begin
                        case (axi_awaddr_reg[3:0])
                            ADDR_TRIGGER: trigger <= s_axi_wdata[0];
                            ADDR_PATTERN: pattern <= s_axi_wdata[7:0];
                        endcase
                    end
                    
                    // Set response
                    s_axi_bresp <= 2'b00; // OKAY response
                    s_axi_bvalid <= 1'b1;
                    write_state <= WRITE_RESP;
                end
                
                WRITE_RESP: begin
                    if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        write_state <= WRITE_IDLE;
                    end
                end
                
                default: write_state <= WRITE_IDLE;
            endcase
        end
    end
    
    // Read transaction handling
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            read_state <= READ_IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b00;
            axi_araddr_reg <= 32'h0;
            s_axi_rdata <= 32'h0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    if (s_axi_arvalid) begin
                        s_axi_arready <= 1'b1;
                        axi_araddr_reg <= s_axi_araddr;
                        read_state <= READ_ADDR;
                    end
                end
                
                READ_ADDR: begin
                    s_axi_arready <= 1'b0;
                    s_axi_rvalid <= 1'b1;
                    
                    // Return register data based on address
                    case (axi_araddr_reg[3:0])
                        ADDR_TRIGGER: s_axi_rdata <= {31'h0, trigger};
                        ADDR_PATTERN: s_axi_rdata <= {24'h0, pattern};
                        ADDR_RESET_SEQ: s_axi_rdata <= {24'h0, reset_seq};
                        default: s_axi_rdata <= 32'h0;
                    endcase
                    
                    s_axi_rresp <= 2'b00; // OKAY response
                    read_state <= READ_DATA;
                end
                
                READ_DATA: begin
                    if (s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        read_state <= READ_IDLE;
                    end
                end
                
                default: read_state <= READ_IDLE;
            endcase
        end
    end
    
    // Core functionality from original module - first pipeline stage
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            bit_pos_next <= 3'b0;
            reset_seq_next <= 8'h0;
        end else begin
            // Compute next state logic
            if (trigger) begin
                bit_pos_next <= 3'b0;
                reset_seq_next <= 8'h0;
            end
            else if (bit_pos < 3'b111) begin
                bit_pos_next <= bit_pos + 1'b1;
                reset_seq_next <= reset_seq;
                reset_seq_next[bit_pos] <= pattern[bit_pos];
            end
            else begin
                bit_pos_next <= bit_pos;
                reset_seq_next <= reset_seq;
            end
        end
    end
    
    // Core functionality from original module - second pipeline stage
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            bit_pos <= 3'b0;
            reset_seq <= 8'h0;
        end else begin
            bit_pos <= bit_pos_next;
            reset_seq <= reset_seq_next;
        end
    end

endmodule