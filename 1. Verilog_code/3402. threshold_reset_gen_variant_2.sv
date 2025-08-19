//SystemVerilog
module threshold_reset_gen(
    // Clock and Reset
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
    
    // Original functionality output
    output reg reset_out
);

    // Register addresses
    localparam ADDR_SIGNAL_VALUE = 4'h0;
    localparam ADDR_THRESHOLD = 4'h4;
    localparam ADDR_STATUS = 4'h8;
    
    // Internal registers
    reg [7:0] signal_value;
    reg [7:0] threshold;
    reg [2:0] status_reg;
    
    // State definitions
    localparam IDLE = 2'b00;
    localparam WRITE = 2'b01;
    localparam READ = 2'b10;
    localparam RESP = 2'b11;
    
    // FSM states
    reg [1:0] write_state;
    reg [1:0] read_state;
    
    // Pre-decode address for faster register selection
    wire is_addr_signal = (s_axi_awaddr[3:0] == ADDR_SIGNAL_VALUE);
    wire is_addr_threshold = (s_axi_awaddr[3:0] == ADDR_THRESHOLD);
    wire is_addr_status = (s_axi_awaddr[3:0] == ADDR_STATUS);
    
    wire is_raddr_signal = (s_axi_araddr[3:0] == ADDR_SIGNAL_VALUE);
    wire is_raddr_threshold = (s_axi_araddr[3:0] == ADDR_THRESHOLD);
    wire is_raddr_status = (s_axi_araddr[3:0] == ADDR_STATUS);
    
    // Early detection of write request
    wire write_request = s_axi_awvalid && s_axi_wvalid;
    
    // AXI4-Lite write transaction handling
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;
            signal_value <= 8'h00;
            threshold <= 8'h00;
            status_reg <= 3'h0;
            write_state <= IDLE;
        end
        else begin
            case (write_state)
                IDLE: begin
                    if (write_request) begin
                        s_axi_awready <= 1'b1;
                        s_axi_wready <= 1'b1;
                        write_state <= WRITE;
                    end
                end
                
                WRITE: begin
                    s_axi_awready <= 1'b0;
                    s_axi_wready <= 1'b0;
                    
                    // Update registers in parallel using pre-decoded address
                    if (is_addr_signal && s_axi_wstrb[0]) 
                        signal_value <= s_axi_wdata[7:0];
                    
                    if (is_addr_threshold && s_axi_wstrb[0]) 
                        threshold <= s_axi_wdata[7:0];
                    
                    if (is_addr_status && s_axi_wstrb[0]) 
                        status_reg <= s_axi_wdata[2:0];
                    
                    // Prepare response
                    s_axi_bresp <= 2'b00; // OKAY response
                    s_axi_bvalid <= 1'b1;
                    write_state <= RESP;
                end
                
                RESP: begin
                    if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        write_state <= IDLE;
                    end
                end
                
                default: begin
                    write_state <= IDLE;
                end
            endcase
        end
    end
    
    // Pre-computed read data for each register
    wire [31:0] signal_value_extended = {24'h0, signal_value};
    wire [31:0] threshold_extended = {24'h0, threshold};
    wire [31:0] status_reg_extended = {29'h0, status_reg};
    
    // Read data multiplexer
    reg [31:0] read_data_mux;
    
    always @(*) begin
        if (is_raddr_signal)
            read_data_mux = signal_value_extended;
        else if (is_raddr_threshold)
            read_data_mux = threshold_extended;
        else if (is_raddr_status)
            read_data_mux = status_reg_extended;
        else
            read_data_mux = 32'h0;
    end
    
    // AXI4-Lite read transaction handling
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rdata <= 32'h0;
            s_axi_rresp <= 2'b00;
            read_state <= IDLE;
        end
        else begin
            case (read_state)
                IDLE: begin
                    if (s_axi_arvalid) begin
                        s_axi_arready <= 1'b1;
                        read_state <= READ;
                    end
                end
                
                READ: begin
                    s_axi_arready <= 1'b0;
                    
                    // Use pre-computed read data
                    s_axi_rdata <= read_data_mux;
                    s_axi_rresp <= 2'b00; // OKAY response
                    s_axi_rvalid <= 1'b1;
                    read_state <= RESP;
                end
                
                RESP: begin
                    if (s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        read_state <= IDLE;
                    end
                end
                
                default: begin
                    read_state <= IDLE;
                end
            endcase
        end
    end
    
    // Pre-compute comparison result for use in threshold checking
    wire threshold_exceeded = signal_value > threshold;
    wire reset_update_needed = status_reg[0];
    
    // Original functionality: compare signal_value with threshold
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            reset_out <= 1'b0;
        end
        else if (reset_update_needed) begin
            reset_out <= threshold_exceeded;
        end
    end

endmodule