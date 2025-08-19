//SystemVerilog
// Top level module with AXI4-Lite interface
module watchdog_timer (
    // Global signals
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    
    // AXI4-Lite write address channel
    input  wire [31:0] s_axi_awaddr,
    input  wire [2:0]  s_axi_awprot,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    
    // AXI4-Lite write data channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    
    // AXI4-Lite write response channel
    output wire [1:0]  s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    
    // AXI4-Lite read address channel
    input  wire [31:0] s_axi_araddr,
    input  wire [2:0]  s_axi_arprot,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    
    // AXI4-Lite read data channel
    output wire [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,
    
    // Watchdog outputs
    output wire        timeout,
    output wire [2:0]  warn_level
);

    // Register map (byte addressing):
    // 0x00: Control Register [bit0: kick, bit1: update_timeout]
    // 0x04: Status Register [bit0: timeout, bits3:1: warn_level]
    // 0x08: Timeout Value Register [15:0]
    
    // Internal signals
    reg [15:0] timeout_value;
    reg update_timeout;
    reg kick;
    
    wire [1:0] state;
    wire [15:0] counter;
    wire [15:0] timeout_reg;
    wire [1:0] next_state;
    
    // AXI4-Lite interface registers
    reg [31:0] reg_data_out;
    reg s_axi_awready_reg;
    reg s_axi_wready_reg;
    reg s_axi_bvalid_reg;
    reg s_axi_arready_reg;
    reg s_axi_rvalid_reg;
    reg [1:0] s_axi_bresp_reg;
    reg [1:0] s_axi_rresp_reg;
    
    // Write address capture
    reg [31:0] axi_awaddr;
    // Read address capture
    reg [31:0] axi_araddr;
    
    // Assign AXI outputs
    assign s_axi_awready = s_axi_awready_reg;
    assign s_axi_wready = s_axi_wready_reg;
    assign s_axi_bresp = s_axi_bresp_reg;
    assign s_axi_bvalid = s_axi_bvalid_reg;
    assign s_axi_arready = s_axi_arready_reg;
    assign s_axi_rdata = reg_data_out;
    assign s_axi_rresp = s_axi_rresp_reg;
    assign s_axi_rvalid = s_axi_rvalid_reg;
    
    // Write address handshake
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_awready_reg <= 1'b0;
            axi_awaddr <= 32'b0;
        end else begin
            if (~s_axi_awready_reg && s_axi_awvalid) begin
                s_axi_awready_reg <= 1'b1;
                axi_awaddr <= s_axi_awaddr;
            end else begin
                s_axi_awready_reg <= 1'b0;
            end
        end
    end
    
    // Write data handshake
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_wready_reg <= 1'b0;
            update_timeout <= 1'b0;
            kick <= 1'b0;
            timeout_value <= 16'd1000; // Default timeout
        end else begin
            update_timeout <= 1'b0; // Single pulse
            kick <= 1'b0;          // Single pulse
            
            if (~s_axi_wready_reg && s_axi_wvalid && s_axi_awready_reg) begin
                s_axi_wready_reg <= 1'b1;
                
                case (axi_awaddr[7:2])
                    6'h00: begin // Control register
                        if (s_axi_wstrb[0]) begin
                            kick <= s_axi_wdata[0];
                            update_timeout <= s_axi_wdata[1];
                        end
                    end
                    6'h02: begin // Timeout value register
                        if (s_axi_wstrb[0]) timeout_value[7:0] <= s_axi_wdata[7:0];
                        if (s_axi_wstrb[1]) timeout_value[15:8] <= s_axi_wdata[15:8];
                    end
                    default: begin
                        // No action for other addresses
                    end
                endcase
            end else begin
                s_axi_wready_reg <= 1'b0;
            end
        end
    end
    
    // Write response channel
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_bvalid_reg <= 1'b0;
            s_axi_bresp_reg <= 2'b0;
        end else begin
            if (s_axi_awready_reg && s_axi_wready_reg && ~s_axi_bvalid_reg) begin
                s_axi_bvalid_reg <= 1'b1;
                s_axi_bresp_reg <= 2'b00; // OKAY response
            end else if (s_axi_bready && s_axi_bvalid_reg) begin
                s_axi_bvalid_reg <= 1'b0;
            end
        end
    end
    
    // Read address handshake
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_arready_reg <= 1'b0;
            axi_araddr <= 32'b0;
        end else begin
            if (~s_axi_arready_reg && s_axi_arvalid) begin
                s_axi_arready_reg <= 1'b1;
                axi_araddr <= s_axi_araddr;
            end else begin
                s_axi_arready_reg <= 1'b0;
            end
        end
    end
    
    // Read data channel
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_rvalid_reg <= 1'b0;
            s_axi_rresp_reg <= 2'b0;
        end else begin
            if (s_axi_arready_reg && ~s_axi_rvalid_reg) begin
                s_axi_rvalid_reg <= 1'b1;
                s_axi_rresp_reg <= 2'b00; // OKAY response
                
                // Output register select
                case (axi_araddr[7:2])
                    6'h00: begin // Control register - read returns 0
                        reg_data_out <= 32'h0;
                    end
                    6'h01: begin // Status register
                        reg_data_out <= {28'h0, warn_level, timeout};
                    end
                    6'h02: begin // Timeout value register
                        reg_data_out <= {16'h0, timeout_value};
                    end
                    6'h03: begin // Counter value (read-only)
                        reg_data_out <= {16'h0, counter};
                    end
                    default: begin
                        reg_data_out <= 32'h0;
                    end
                endcase
            end else if (s_axi_rready && s_axi_rvalid_reg) begin
                s_axi_rvalid_reg <= 1'b0;
            end
        end
    end
    
    // Instantiate submodules
    watchdog_state_controller state_ctrl (
        .clk(s_axi_aclk),
        .rst_n(s_axi_aresetn),
        .counter(counter),
        .timeout_reg(timeout_reg),
        .kick(kick),
        .state(state),
        .next_state(next_state)
    );

    watchdog_counter counter_unit (
        .clk(s_axi_aclk),
        .rst_n(s_axi_aresetn),
        .state(state),
        .kick(kick),
        .counter(counter)
    );

    watchdog_timeout_reg timeout_reg_unit (
        .clk(s_axi_aclk),
        .rst_n(s_axi_aresetn),
        .update_timeout(update_timeout),
        .timeout_value(timeout_value),
        .timeout_reg(timeout_reg)
    );

    watchdog_output_control output_ctrl (
        .clk(s_axi_aclk),
        .rst_n(s_axi_aresetn),
        .state(state),
        .counter(counter),
        .timeout_reg(timeout_reg),
        .timeout(timeout),
        .warn_level(warn_level)
    );

endmodule

// State controller module
module watchdog_state_controller(
    input wire clk, rst_n,
    input wire [15:0] counter,
    input wire [15:0] timeout_reg,
    input wire kick,
    output reg [1:0] state,
    output reg [1:0] next_state
);
    localparam IDLE=2'b00, COUNTING=2'b01, TIMEOUT=2'b10, RESET=2'b11;

    always @(posedge clk or negedge rst_n)
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;

    always @(*)
        case (state)
            IDLE: next_state = COUNTING;
            COUNTING: begin
                if (counter >= timeout_reg) 
                    next_state = TIMEOUT;
                else
                    next_state = COUNTING;
            end
            TIMEOUT: begin
                if (kick)
                    next_state = RESET;
                else
                    next_state = TIMEOUT;
            end
            RESET: next_state = COUNTING;
            default: next_state = IDLE;
        endcase
endmodule

// Counter module
module watchdog_counter(
    input wire clk, rst_n,
    input wire [1:0] state,
    input wire kick,
    output reg [15:0] counter
);
    localparam IDLE=2'b00, COUNTING=2'b01, TIMEOUT=2'b10, RESET=2'b11;

    always @(posedge clk or negedge rst_n)
        if (!rst_n)
            counter <= 16'd0;
        else
            case (state)
                IDLE, RESET: counter <= 16'd0;
                COUNTING: begin
                    if (kick)
                        counter <= 16'd0;
                    else
                        counter <= counter + 16'd1;
                end
                default: counter <= counter;
            endcase
endmodule

// Timeout register module
module watchdog_timeout_reg(
    input wire clk, rst_n,
    input wire update_timeout,
    input wire [15:0] timeout_value,
    output reg [15:0] timeout_reg
);

    always @(posedge clk or negedge rst_n)
        if (!rst_n)
            timeout_reg <= 16'd1000; // Default timeout
        else if (update_timeout)
            timeout_reg <= timeout_value;
endmodule

// Output control module
module watchdog_output_control(
    input wire clk, rst_n,
    input wire [1:0] state,
    input wire [15:0] counter,
    input wire [15:0] timeout_reg,
    output reg timeout,
    output reg [2:0] warn_level
);
    localparam IDLE=2'b00, COUNTING=2'b01, TIMEOUT=2'b10, RESET=2'b11;

    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            timeout <= 1'b0;
            warn_level <= 3'd0;
        end
        else
            case (state)
                IDLE, RESET: begin
                    timeout <= 1'b0;
                    warn_level <= 3'd0;
                end
                COUNTING: begin
                    timeout <= 1'b0;
                    if (counter > (timeout_reg >> 1))
                        warn_level <= 3'd3;
                    else if (counter > (timeout_reg >> 2))
                        warn_level <= 3'd2;
                    else if (counter > (timeout_reg >> 3))
                        warn_level <= 3'd1;
                    else
                        warn_level <= 3'd0;
                end
                TIMEOUT: begin
                    timeout <= 1'b1;
                    warn_level <= 3'd7;
                end
                default: begin
                    timeout <= timeout;
                    warn_level <= warn_level;
                end
            endcase
endmodule