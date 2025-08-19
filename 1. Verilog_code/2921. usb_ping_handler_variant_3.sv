//SystemVerilog
//IEEE 1364-2005 SystemVerilog
module usb_ping_handler (
    input wire clk_i,
    input wire rst_n_i,
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input wire [31:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
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
    input wire [2:0] s_axil_arprot,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // Read Data Channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready
);

    // State encodings - one-hot encoding for improved timing
    localparam [1:0] IDLE = 2'b01;
    localparam [1:0] CHECK = 2'b10;
    localparam [1:0] RESPOND = 2'b11;
    localparam [1:0] COMPLETE = 2'b00;
    
    // Internal signals
    reg ping_received;
    reg [3:0] endpoint;
    reg [7:0] buffer_status;
    reg ack_response;
    reg nak_response;
    reg stall_response;
    reg ping_handled;
    reg [1:0] ping_state;
    
    // Memory mapped registers
    reg [7:0] endpoint_buffer_status [0:15];  // Status for each endpoint
    reg [3:0] endpoint_stall_status;          // Stall status for endpoints
    
    // AXI FSM states - one-hot encoding for better timing
    localparam [2:0] AXIL_IDLE  = 3'b001;
    localparam [2:0] AXIL_WADDR = 3'b010;
    localparam [2:0] AXIL_WDATA = 3'b011;
    localparam [2:0] AXIL_WRESP = 3'b100;
    localparam [2:0] AXIL_RADDR = 3'b101;
    localparam [2:0] AXIL_RDATA = 3'b110;
    localparam [2:0] AXIL_RCOMP = 3'b111;
    
    reg [2:0] axil_state;
    reg [7:0] axil_addr_masked; // Optimized to just store the relevant bits
    wire is_ping_control_addr;
    wire is_buffer_status_addr;
    wire is_stall_status_addr;

    // Address decode - optimize comparison logic
    assign is_ping_control_addr  = (axil_addr_masked == 8'h00);
    assign is_buffer_status_addr = (axil_addr_masked == 8'h04);
    assign is_stall_status_addr  = (axil_addr_masked == 8'h08);
    
    // AXI4-Lite interface implementation
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            axil_state <= AXIL_IDLE;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= 2'b00;
            ping_received <= 1'b0;
            endpoint <= 4'h0;
            buffer_status <= 8'h0;
            endpoint_stall_status <= 4'h0;
            axil_addr_masked <= 8'h0;
        end else begin
            // Default assignments
            ping_received <= 1'b0;
            
            case (axil_state)
                AXIL_IDLE: begin
                    s_axil_awready <= 1'b1;
                    s_axil_arready <= 1'b1;
                    
                    if (s_axil_awvalid) begin
                        axil_addr_masked <= s_axil_awaddr[7:0];
                        s_axil_awready <= 1'b0;
                        s_axil_wready <= 1'b1;
                        axil_state <= AXIL_WDATA;
                    end else if (s_axil_arvalid) begin
                        axil_addr_masked <= s_axil_araddr[7:0];
                        s_axil_arready <= 1'b0;
                        axil_state <= AXIL_RDATA;
                    end
                end
                
                AXIL_WDATA: begin
                    if (s_axil_wvalid) begin
                        s_axil_wready <= 1'b0;
                        s_axil_bvalid <= 1'b1;
                        s_axil_bresp <= 2'b00; // OKAY response
                        
                        // Optimized register write logic with prioritized checks
                        if (is_ping_control_addr && s_axil_wstrb[0]) begin
                            ping_received <= s_axil_wdata[0];
                            endpoint <= s_axil_wdata[7:4];
                        end else if (is_buffer_status_addr && s_axil_wstrb[0]) begin
                            buffer_status <= s_axil_wdata[7:0];
                        end else if (is_stall_status_addr && s_axil_wstrb[0]) begin
                            endpoint_stall_status <= s_axil_wdata[3:0];
                        end
                        
                        axil_state <= AXIL_WRESP;
                    end
                end
                
                AXIL_WRESP: begin
                    if (s_axil_bready) begin
                        s_axil_bvalid <= 1'b0;
                        axil_state <= AXIL_IDLE;
                    end
                end
                
                AXIL_RDATA: begin
                    s_axil_rvalid <= 1'b1;
                    s_axil_rresp <= 2'b00; // OKAY response
                    
                    // Optimized register read with prioritized checks
                    if (is_ping_control_addr) begin
                        s_axil_rdata <= {24'h0, ping_state, ack_response, nak_response, stall_response, ping_handled};
                    end else if (is_buffer_status_addr) begin
                        s_axil_rdata <= {24'h0, buffer_status};
                    end else if (is_stall_status_addr) begin
                        s_axil_rdata <= {28'h0, endpoint_stall_status};
                    end else begin
                        s_axil_rdata <= 32'h0;
                    end
                    
                    axil_state <= AXIL_RCOMP;
                end
                
                AXIL_RCOMP: begin
                    if (s_axil_rready) begin
                        s_axil_rvalid <= 1'b0;
                        axil_state <= AXIL_IDLE;
                    end
                end
                
                default: begin
                    axil_state <= AXIL_IDLE;
                end
            endcase
        end
    end
    
    // USB ping handler response select logic
    reg stall_condition;
    reg buffer_available;
    
    // Optimized comparator logic - precompute conditions
    always @(*) begin
        stall_condition = endpoint_stall_status[endpoint];
        buffer_available = (buffer_status != 8'd0);
    end
    
    // USB ping handler core logic
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            ping_state <= IDLE;
            ack_response <= 1'b0;
            nak_response <= 1'b0;
            stall_response <= 1'b0;
            ping_handled <= 1'b0;
        end else begin
            case (ping_state)
                IDLE: begin
                    ack_response <= 1'b0;
                    nak_response <= 1'b0;
                    stall_response <= 1'b0;
                    ping_handled <= 1'b0;
                    
                    if (ping_received)
                        ping_state <= CHECK;
                end
                
                CHECK: begin
                    // Optimized comparison chain using precomputed conditions
                    if (stall_condition) begin
                        stall_response <= 1'b1;
                        ack_response <= 1'b0;
                        nak_response <= 1'b0;
                    end else if (buffer_available) begin
                        stall_response <= 1'b0;
                        ack_response <= 1'b1;
                        nak_response <= 1'b0;
                    end else begin
                        stall_response <= 1'b0;
                        ack_response <= 1'b0;
                        nak_response <= 1'b1;
                    end
                    ping_state <= RESPOND;
                end
                
                RESPOND: begin
                    ping_handled <= 1'b1;
                    ping_state <= COMPLETE;
                end
                
                COMPLETE: begin
                    // Parallel reset of all response signals for improved timing
                    {ack_response, nak_response, stall_response, ping_handled} <= 4'b0000;
                    ping_state <= IDLE;
                end
                
                default: begin
                    ping_state <= IDLE;
                end
            endcase
        end
    end
endmodule