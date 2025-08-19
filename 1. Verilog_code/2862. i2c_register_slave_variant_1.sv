//SystemVerilog
module i2c_register_slave_axi4lite(
    // Clock and Reset
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    
    // AXI4-Lite Write Address Channel
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    
    // AXI4-Lite Write Data Channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    
    // AXI4-Lite Write Response Channel
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    
    // AXI4-Lite Read Address Channel
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    
    // AXI4-Lite Read Data Channel
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    
    // I2C Interface
    inout  wire        sda,
    inout  wire        scl,
    
    // Device configuration
    input  wire [6:0]  device_address,
    output wire [7:0]  reg_data_out
);

    // Internal registers
    reg [7:0] registers [0:15];
    reg [3:0] reg_addr;
    reg [7:0] rx_shift_reg;
    reg [3:0] bit_cnt;
    reg [2:0] state;
    reg addr_matched, addr_phase, reg_addr_received;
    
    // AXI Write signals
    reg [31:0] axi_awaddr;
    reg axi_write_active;
    reg axi_aw_captured;
    reg axi_w_captured;
    
    // AXI Read signals
    reg [31:0] axi_araddr;
    reg axi_read_active;
    
    // Address range validation
    wire addr_in_valid_range;
    wire [3:0] register_index;
    
    // I2C core functionality output
    assign reg_data_out = registers[reg_addr];
    
    // Address validation
    assign register_index = axi_awaddr[5:2];
    assign addr_in_valid_range = (register_index < 4'd15);
    
    // AXI Write Address Channel - State machine
    localparam AWREADY_IDLE = 1'b0;
    localparam AWREADY_ACTIVE = 1'b1;
    
    reg awready_state;
    reg awready_next;
    
    // AXI Write Address Channel - Next state logic
    always @(*) begin
        awready_next = awready_state;
        
        case (awready_state)
            AWREADY_IDLE: begin
                if (s_axi_awvalid && ~axi_write_active) begin
                    awready_next = AWREADY_ACTIVE;
                end
            end
            
            AWREADY_ACTIVE: begin
                awready_next = AWREADY_IDLE;
            end
        endcase
    end
    
    // AXI Write Address Channel - State register and outputs
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (~s_axi_aresetn) begin
            awready_state <= AWREADY_IDLE;
            s_axi_awready <= 1'b0;
            axi_awaddr <= 32'h0;
            axi_aw_captured <= 1'b0;
        end else begin
            awready_state <= awready_next;
            
            case (awready_state)
                AWREADY_IDLE: begin
                    if (awready_next == AWREADY_ACTIVE) begin
                        s_axi_awready <= 1'b1;
                        axi_awaddr <= s_axi_awaddr;
                        axi_aw_captured <= 1'b1;
                    end
                end
                
                AWREADY_ACTIVE: begin
                    s_axi_awready <= 1'b0;
                end
            endcase
            
            if (s_axi_bready && s_axi_bvalid) begin
                axi_aw_captured <= 1'b0;
            end
        end
    end

    // AXI Write Data Channel - State machine
    localparam WREADY_IDLE = 1'b0;
    localparam WREADY_ACTIVE = 1'b1;
    
    reg wready_state;
    reg wready_next;
    
    // AXI Write Data Channel - Next state logic
    always @(*) begin
        wready_next = wready_state;
        
        case (wready_state)
            WREADY_IDLE: begin
                if (s_axi_wvalid && axi_aw_captured && ~axi_w_captured) begin
                    wready_next = WREADY_ACTIVE;
                end
            end
            
            WREADY_ACTIVE: begin
                wready_next = WREADY_IDLE;
            end
        endcase
    end
    
    // AXI Write Data Channel - State register and outputs
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (~s_axi_aresetn) begin
            wready_state <= WREADY_IDLE;
            s_axi_wready <= 1'b0;
            s_axi_bresp <= 2'b00;
            s_axi_bvalid <= 1'b0;
            axi_w_captured <= 1'b0;
            axi_write_active <= 1'b0;
        end else begin
            wready_state <= wready_next;
            
            case (wready_state)
                WREADY_IDLE: begin
                    if (wready_next == WREADY_ACTIVE) begin
                        s_axi_wready <= 1'b1;
                        axi_write_active <= 1'b1;
                        axi_w_captured <= 1'b1;
                        
                        // Decision tree for register write operations
                        if (addr_in_valid_range) begin
                            // Valid register address
                            if (s_axi_wstrb[0]) begin
                                registers[register_index][7:0] <= s_axi_wdata[7:0];
                            end
                            s_axi_bresp <= 2'b00; // OKAY
                        end else begin
                            // Invalid register address
                            s_axi_bresp <= 2'b10; // SLVERR
                        end
                        
                        s_axi_bvalid <= 1'b1;
                    end
                end
                
                WREADY_ACTIVE: begin
                    s_axi_wready <= 1'b0;
                end
            endcase
            
            if (s_axi_bready && s_axi_bvalid) begin
                s_axi_bvalid <= 1'b0;
                axi_write_active <= 1'b0;
                axi_w_captured <= 1'b0;
            end
        end
    end

    // AXI Read Address Channel - State machine
    localparam ARREADY_IDLE = 1'b0;
    localparam ARREADY_ACTIVE = 1'b1;
    
    reg arready_state;
    reg arready_next;
    
    // AXI Read Address Channel - Next state logic
    always @(*) begin
        arready_next = arready_state;
        
        case (arready_state)
            ARREADY_IDLE: begin
                if (s_axi_arvalid && ~axi_read_active) begin
                    arready_next = ARREADY_ACTIVE;
                end
            end
            
            ARREADY_ACTIVE: begin
                arready_next = ARREADY_IDLE;
            end
        endcase
    end
    
    // AXI Read Address Channel - State register and outputs
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (~s_axi_aresetn) begin
            arready_state <= ARREADY_IDLE;
            s_axi_arready <= 1'b0;
            axi_araddr <= 32'h0;
            axi_read_active <= 1'b0;
        end else begin
            arready_state <= arready_next;
            
            case (arready_state)
                ARREADY_IDLE: begin
                    if (arready_next == ARREADY_ACTIVE) begin
                        s_axi_arready <= 1'b1;
                        axi_araddr <= s_axi_araddr;
                        axi_read_active <= 1'b1;
                    end
                end
                
                ARREADY_ACTIVE: begin
                    s_axi_arready <= 1'b0;
                end
            endcase
            
            if (s_axi_rready && s_axi_rvalid) begin
                axi_read_active <= 1'b0;
            end
        end
    end

    // AXI Read Data Channel - State machine
    localparam RVALID_IDLE = 1'b0;
    localparam RVALID_ACTIVE = 1'b1;
    
    reg rvalid_state;
    reg rvalid_next;
    wire [3:0] read_register_index;
    wire read_addr_in_valid_range;
    
    assign read_register_index = axi_araddr[5:2];
    assign read_addr_in_valid_range = (read_register_index < 4'd15);
    
    // AXI Read Data Channel - Next state logic
    always @(*) begin
        rvalid_next = rvalid_state;
        
        case (rvalid_state)
            RVALID_IDLE: begin
                if (axi_read_active && ~s_axi_rvalid) begin
                    rvalid_next = RVALID_ACTIVE;
                end
            end
            
            RVALID_ACTIVE: begin
                if (s_axi_rready) begin
                    rvalid_next = RVALID_IDLE;
                end
            end
        endcase
    end
    
    // AXI Read Data Channel - State register and outputs
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (~s_axi_aresetn) begin
            rvalid_state <= RVALID_IDLE;
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b00;
            s_axi_rdata <= 32'h0;
        end else begin
            rvalid_state <= rvalid_next;
            
            case (rvalid_state)
                RVALID_IDLE: begin
                    if (rvalid_next == RVALID_ACTIVE) begin
                        s_axi_rvalid <= 1'b1;
                        
                        // Decision tree for register read operations
                        if (read_addr_in_valid_range) begin
                            // Valid register address
                            s_axi_rdata <= {24'h0, registers[read_register_index]};
                            s_axi_rresp <= 2'b00; // OKAY
                        end else begin
                            // Invalid register address
                            s_axi_rdata <= 32'h0;
                            s_axi_rresp <= 2'b10; // SLVERR
                        end
                    end
                end
                
                RVALID_ACTIVE: begin
                    if (rvalid_next == RVALID_IDLE) begin
                        s_axi_rvalid <= 1'b0;
                    end
                end
            endcase
        end
    end

    // I2C core functionality (preserved from original design)
    // Restructured to use decisions tree and clear state transitions
    localparam I2C_IDLE          = 3'b000;
    localparam I2C_ADDR_MATCH    = 3'b001;
    localparam I2C_REG_ADDR      = 3'b010;
    localparam I2C_DATA_TRANSFER = 3'b011;
    localparam I2C_ERROR         = 3'b100;
    
    always @(posedge scl or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            state <= I2C_IDLE;
            reg_addr <= 4'h0;
            rx_shift_reg <= 8'h0;
            bit_cnt <= 4'h0;
            addr_matched <= 1'b0;
            addr_phase <= 1'b0;
            reg_addr_received <= 1'b0;
        end else begin
            // Decision tree for I2C state machine
            case (state)
                I2C_IDLE: begin
                    // Default state behavior
                end
                
                I2C_ADDR_MATCH: begin
                    // Address matching state
                end
                
                I2C_REG_ADDR: begin
                    // Register address reception
                    if (bit_cnt == 4'd8) begin
                        reg_addr <= rx_shift_reg[3:0];
                        reg_addr_received <= 1'b1;
                    end
                end
                
                I2C_DATA_TRANSFER: begin
                    // Data transfer state
                end
                
                I2C_ERROR: begin
                    // Error handling state
                end
                
                default: begin
                    state <= I2C_IDLE;
                end
            endcase
        end
    end

endmodule