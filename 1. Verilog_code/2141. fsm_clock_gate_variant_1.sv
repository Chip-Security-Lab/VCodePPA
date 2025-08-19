//SystemVerilog
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
module fsm_clock_gate_axi (
    // Global Clock and Reset
    input  wire         s_axi_aclk,
    input  wire         s_axi_aresetn,
    
    // AXI4-Lite Write Address Channel
    input  wire [31:0]  s_axi_awaddr,
    input  wire         s_axi_awvalid,
    output wire         s_axi_awready,
    
    // AXI4-Lite Write Data Channel
    input  wire [31:0]  s_axi_wdata,
    input  wire [3:0]   s_axi_wstrb,
    input  wire         s_axi_wvalid,
    output wire         s_axi_wready,
    
    // AXI4-Lite Write Response Channel
    output wire [1:0]   s_axi_bresp,
    output wire         s_axi_bvalid,
    input  wire         s_axi_bready,
    
    // AXI4-Lite Read Address Channel
    input  wire [31:0]  s_axi_araddr,
    input  wire         s_axi_arvalid,
    output wire         s_axi_arready,
    
    // AXI4-Lite Read Data Channel
    output wire [31:0]  s_axi_rdata,
    output wire [1:0]   s_axi_rresp,
    output wire         s_axi_rvalid,
    input  wire         s_axi_rready,
    
    // Clock output (original functionality)
    output wire         clk_out
);

    // Parameter and Localparam definitions
    localparam IDLE = 1'b0, ACTIVE = 1'b1;
    localparam ADDR_START = 4'h0;
    localparam ADDR_DONE  = 4'h4;
    localparam ADDR_STATUS = 4'h8;
    
    // AXI response codes
    localparam RESP_OKAY = 2'b00;
    localparam RESP_SLVERR = 2'b10;
    
    // Internal signals for original FSM functionality
    reg  state, next_state;
    reg  start_reg;
    reg  done_reg;
    wire clk_in;
    
    // AXI handshake control registers
    reg  write_addr_valid;
    reg  write_data_valid;
    reg  write_resp_valid;
    reg  read_addr_valid;
    reg  read_data_valid;
    
    reg [31:0] read_data;
    reg [3:0]  write_addr;
    reg [31:0] write_data;
    reg [3:0]  read_addr;
    
    // Map AXI clock to internal clock
    assign clk_in = s_axi_aclk;
    
    // AXI4-Lite interface - Write address channel
    assign s_axi_awready = ~write_addr_valid;
    
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (~s_axi_aresetn) 
            write_addr_valid <= 1'b0;
        else if (s_axi_awvalid && s_axi_awready) begin
            write_addr_valid <= 1'b1;
            write_addr <= s_axi_awaddr[5:2];
        end
        else if (s_axi_wvalid && s_axi_wready)
            write_addr_valid <= 1'b0;
    end
    
    // AXI4-Lite interface - Write data channel
    assign s_axi_wready = write_addr_valid & ~write_data_valid;
    
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (~s_axi_aresetn) 
            write_data_valid <= 1'b0;
        else if (s_axi_wvalid && s_axi_wready) begin
            write_data_valid <= 1'b1;
            write_data <= s_axi_wdata;
        end
        else if (write_resp_valid && s_axi_bready)
            write_data_valid <= 1'b0;
    end
    
    // AXI4-Lite interface - Write response channel
    assign s_axi_bvalid = write_resp_valid;
    assign s_axi_bresp = RESP_OKAY;
    
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (~s_axi_aresetn) 
            write_resp_valid <= 1'b0;
        else if (write_data_valid && ~write_resp_valid)
            write_resp_valid <= 1'b1;
        else if (s_axi_bready)
            write_resp_valid <= 1'b0;
    end
    
    // AXI4-Lite interface - Read address channel
    assign s_axi_arready = ~read_addr_valid;
    
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (~s_axi_aresetn) 
            read_addr_valid <= 1'b0;
        else if (s_axi_arvalid && s_axi_arready) begin
            read_addr_valid <= 1'b1;
            read_addr <= s_axi_araddr[5:2];
        end
        else if (read_data_valid && s_axi_rready)
            read_addr_valid <= 1'b0;
    end
    
    // AXI4-Lite interface - Read data channel
    assign s_axi_rvalid = read_data_valid;
    assign s_axi_rdata = read_data;
    assign s_axi_rresp = RESP_OKAY;
    
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (~s_axi_aresetn) begin
            read_data_valid <= 1'b0;
            read_data <= 32'h0;
        end
        else if (read_addr_valid && ~read_data_valid) begin
            read_data_valid <= 1'b1;
            
            case(read_addr)
                ADDR_START[3:0]:  read_data <= {31'h0, start_reg};
                ADDR_DONE[3:0]:   read_data <= {31'h0, done_reg};
                ADDR_STATUS[3:0]: read_data <= {31'h0, state};
                default:          read_data <= 32'h0;
            endcase
        end
        else if (s_axi_rready)
            read_data_valid <= 1'b0;
    end
    
    // Write registers based on AXI writes
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (~s_axi_aresetn) begin
            start_reg <= 1'b0;
            done_reg <= 1'b0;
        end
        else if (write_data_valid) begin
            case(write_addr)
                ADDR_START[3:0]: start_reg <= write_data[0];
                ADDR_DONE[3:0]:  done_reg <= write_data[0];
                default: begin
                    // No action
                end
            endcase
        end
    end
    
    // Original FSM state transition logic
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    always @(*) begin
        case (state)
            IDLE:   next_state = start_reg ? ACTIVE : IDLE;
            ACTIVE: next_state = done_reg ? IDLE : ACTIVE;
            default: next_state = IDLE;
        endcase
    end
    
    // Original clock gating logic
    assign clk_out = s_axi_aclk & (state == ACTIVE);

endmodule