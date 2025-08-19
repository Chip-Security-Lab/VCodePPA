//SystemVerilog
module usb_device_addr_reg (
    input wire clk,
    input wire rst_b,
    
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
    input wire s_axil_rready,
    
    // USB Interface Signals
    input wire [3:0] pid,
    input wire [6:0] token_address,
    output reg address_match
);

    // Internal registers
    reg [6:0] device_address;
    
    // AXI4-Lite Register Map
    // 0x00: Device Address Register [6:0]
    // 0x04: Status Register (read-only)
    
    // Parameters
    localparam PID_SETUP = 4'b1101;
    localparam PID_IN = 4'b1001;
    localparam PID_OUT = 4'b0001;
    
    localparam ADDR_DEVICE_ADDR = 2'b00;
    localparam ADDR_STATUS = 2'b01;
    
    localparam RESP_OKAY = 2'b00;
    localparam RESP_SLVERR = 2'b10;
    
    // Pipeline registers for address comparison
    reg [6:0] token_address_reg;
    reg [3:0] pid_reg;
    reg address_equal;
    reg token_is_zero;
    
    // Write address channel handling
    reg [1:0] write_addr;
    reg write_addr_valid;
    
    // Write data channel handling
    reg [31:0] write_data;
    reg [3:0] write_strb;
    reg write_data_valid;
    
    // Read address channel handling
    reg [1:0] read_addr;
    reg read_addr_valid;
    
    // FSM states
    reg [1:0] write_state;
    reg [1:0] read_state;
    
    localparam IDLE = 2'b00;
    localparam ADDR = 2'b01;
    localparam DATA = 2'b10;
    localparam RESP = 2'b11;
    
    // Write address channel
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            s_axil_awready <= 1'b1;
            write_addr <= 2'b00;
            write_addr_valid <= 1'b0;
            write_state <= IDLE;
        end else begin
            case (write_state)
                IDLE: begin
                    if (s_axil_awvalid && s_axil_awready) begin
                        write_addr <= s_axil_awaddr[3:2];
                        write_addr_valid <= 1'b1;
                        s_axil_awready <= 1'b0;
                        write_state <= ADDR;
                    end
                end
                ADDR: begin
                    if (write_data_valid) begin
                        write_addr_valid <= 1'b0;
                        write_state <= DATA;
                    end
                end
                DATA: begin
                    if (s_axil_bready && s_axil_bvalid) begin
                        s_axil_awready <= 1'b1;
                        write_state <= IDLE;
                    end
                end
                default: write_state <= IDLE;
            endcase
        end
    end
    
    // Write data channel
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            s_axil_wready <= 1'b1;
            write_data <= 32'h0;
            write_strb <= 4'h0;
            write_data_valid <= 1'b0;
        end else begin
            if (s_axil_wvalid && s_axil_wready) begin
                write_data <= s_axil_wdata;
                write_strb <= s_axil_wstrb;
                write_data_valid <= 1'b1;
                s_axil_wready <= 1'b0;
            end else if (write_data_valid && write_addr_valid) begin
                write_data_valid <= 1'b0;
            end else if (s_axil_bready && s_axil_bvalid) begin
                s_axil_wready <= 1'b1;
            end
        end
    end
    
    // Write response channel
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= RESP_OKAY;
        end else begin
            if (write_data_valid && write_addr_valid) begin
                s_axil_bvalid <= 1'b1;
                if (write_addr == ADDR_DEVICE_ADDR && write_strb[0]) begin
                    s_axil_bresp <= RESP_OKAY;
                end else if (write_addr == ADDR_STATUS) begin
                    // Status register is read-only
                    s_axil_bresp <= RESP_SLVERR;
                end else begin
                    s_axil_bresp <= RESP_SLVERR;
                end
            end else if (s_axil_bready && s_axil_bvalid) begin
                s_axil_bvalid <= 1'b0;
            end
        end
    end
    
    // Device address register
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            device_address <= 7'h00;
        end else if (write_data_valid && write_addr_valid && write_addr == ADDR_DEVICE_ADDR && write_strb[0]) begin
            device_address <= write_data[6:0];
        end
    end
    
    // Read address channel
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            s_axil_arready <= 1'b1;
            read_addr <= 2'b00;
            read_addr_valid <= 1'b0;
            read_state <= IDLE;
        end else begin
            case (read_state)
                IDLE: begin
                    if (s_axil_arvalid && s_axil_arready) begin
                        read_addr <= s_axil_araddr[3:2];
                        read_addr_valid <= 1'b1;
                        s_axil_arready <= 1'b0;
                        read_state <= ADDR;
                    end
                end
                ADDR: begin
                    read_state <= RESP;
                end
                RESP: begin
                    if (s_axil_rready && s_axil_rvalid) begin
                        s_axil_arready <= 1'b1;
                        read_addr_valid <= 1'b0;
                        read_state <= IDLE;
                    end
                end
                default: read_state <= IDLE;
            endcase
        end
    end
    
    // Read data channel
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            s_axil_rvalid <= 1'b0;
            s_axil_rdata <= 32'h0;
            s_axil_rresp <= RESP_OKAY;
        end else begin
            if (read_addr_valid && !s_axil_rvalid) begin
                s_axil_rvalid <= 1'b1;
                case (read_addr)
                    ADDR_DEVICE_ADDR: begin
                        s_axil_rdata <= {25'h0, device_address};
                        s_axil_rresp <= RESP_OKAY;
                    end
                    ADDR_STATUS: begin
                        s_axil_rdata <= {28'h0, address_match, pid_reg[2:0]};
                        s_axil_rresp <= RESP_OKAY;
                    end
                    default: begin
                        s_axil_rdata <= 32'h0;
                        s_axil_rresp <= RESP_SLVERR;
                    end
                endcase
            end else if (s_axil_rready && s_axil_rvalid) begin
                s_axil_rvalid <= 1'b0;
            end
        end
    end
    
    // Stage 1: Register inputs and perform comparisons
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            token_address_reg <= 7'h00;
            pid_reg <= 4'h0;
            address_equal <= 1'b0;
            token_is_zero <= 1'b0;
        end else begin
            token_address_reg <= token_address;
            pid_reg <= pid;
            address_equal <= (token_address == device_address);
            token_is_zero <= (token_address == 7'h00);
        end
    end
    
    // Stage 2: Final address matching logic using pipelined values
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            address_match <= 1'b0;
        end else begin
            if (pid_reg == PID_SETUP) begin
                // Accept SETUP transactions addressed to endpoint 0 or our address
                address_match <= address_equal || token_is_zero;
            end else if (pid_reg == PID_IN || pid_reg == PID_OUT) begin
                // Accept IN/OUT only if addressed to us
                address_match <= address_equal;
            end else begin
                address_match <= 1'b0;
            end
        end
    end

endmodule