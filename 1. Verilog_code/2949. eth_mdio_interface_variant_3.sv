//SystemVerilog
module eth_mdio_interface (
    input wire clk,
    input wire reset,
    // Host interface
    input wire [4:0] phy_addr,
    input wire [4:0] reg_addr,
    input wire [15:0] write_data,
    output reg [15:0] read_data,
    input wire read_req,
    input wire write_req,
    output reg ready,
    output reg error,
    // MDIO interface
    output reg mdio_clk,
    inout wire mdio_data
);
    // State encoding optimized for minimum transitions
    localparam [2:0] 
        IDLE     = 3'b000,
        START    = 3'b001,
        OP       = 3'b011,
        PHY_ADDR = 3'b010, 
        REG_ADDR = 3'b110,
        TA       = 3'b111,
        DATA     = 3'b101,
        DONE     = 3'b100;
    
    reg [2:0] state;
    reg [5:0] bit_count;
    reg [31:0] shift_reg;
    reg mdio_out;
    reg mdio_oe; // Output enable for MDIO data
    
    // Registered input signals to improve timing
    reg [4:0] phy_addr_reg;
    reg [4:0] reg_addr_reg;
    reg [15:0] write_data_reg;
    reg read_req_reg, write_req_reg;
    
    // MDIO is a bidirectional signal
    assign mdio_data = mdio_oe ? mdio_out : 1'bz;
    
    // Register input signals to improve timing at input stage
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            phy_addr_reg <= 5'b0;
            reg_addr_reg <= 5'b0;
            write_data_reg <= 16'b0;
            read_req_reg <= 1'b0;
            write_req_reg <= 1'b0;
        end else begin
            // Only update when not busy to reduce toggling
            if (state == IDLE) begin
                phy_addr_reg <= phy_addr;
                reg_addr_reg <= reg_addr;
                write_data_reg <= write_data;
                read_req_reg <= read_req;
                write_req_reg <= write_req;
            end
        end
    end
    
    // MDIO clock divider (uses toggle FF for cleaner 50% duty cycle)
    reg mdio_clk_div;
    always @(posedge clk or posedge reset) begin
        if (reset)
            mdio_clk_div <= 1'b0;
        else
            mdio_clk_div <= ~mdio_clk_div;
    end
    
    // Pre-compute shift register values with optimized bit layout
    wire [31:0] read_shift_reg;
    wire [31:0] write_shift_reg;
    
    // Use concatenation instead of bit-by-bit assignment to reduce critical path
    assign read_shift_reg = {2'b01, 2'b10, phy_addr_reg, reg_addr_reg, 2'b00, 16'h0000};
    assign write_shift_reg = {2'b01, 2'b01, phy_addr_reg, reg_addr_reg, 2'b10, write_data_reg};
    
    // State transition and bit counter logic optimized
    reg next_state_change;
    
    always @(*) begin
        next_state_change = 1'b0;
        
        if (mdio_clk_div && mdio_clk == 1'b0) begin // Only on rising edge of MDC
            case (state)
                START:    next_state_change = (bit_count == 31);
                OP:       next_state_change = (bit_count == 3);
                PHY_ADDR: next_state_change = (bit_count == 4);
                REG_ADDR: next_state_change = (bit_count == 4);
                TA:       next_state_change = (bit_count == 1);
                DATA:     next_state_change = (bit_count == 15);
                default:  next_state_change = 1'b0;
            endcase
        end
    end
    
    // Main state machine
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            bit_count <= 6'd0;
            mdio_clk <= 1'b1;
            mdio_out <= 1'b1;
            mdio_oe <= 1'b0;
            ready <= 1'b1;
            error <= 1'b0;
            read_data <= 16'd0;
            shift_reg <= 32'd0;
        end else if (mdio_clk_div) begin // Only update on MDC clock edge
            case (state)
                IDLE: begin
                    mdio_clk <= 1'b1;
                    mdio_oe <= 1'b0;
                    
                    // Priority encoder for operation selection
                    if (read_req_reg || write_req_reg) begin
                        // Use pre-computed shift register value
                        shift_reg <= read_req_reg ? read_shift_reg : write_shift_reg;
                        state <= START;
                        bit_count <= 6'd0;
                        ready <= 1'b0;
                        error <= 1'b0;
                        mdio_oe <= 1'b1;
                    end
                end
                
                START: begin
                    // Send preamble (32 bits of 1s)
                    mdio_out <= 1'b1;
                    mdio_clk <= ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // On rising edge of MDC
                        if (next_state_change) begin
                            state <= OP;
                            bit_count <= 6'd0;
                        end else begin
                            bit_count <= bit_count + 1'b1;
                        end
                    end
                end
                
                OP: begin
                    // Send START (01) and OP code (01=write, 10=read)
                    mdio_out <= shift_reg[31-bit_count];
                    mdio_clk <= ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // On rising edge of MDC
                        if (next_state_change) begin
                            state <= PHY_ADDR;
                            bit_count <= 6'd0;
                        end else begin
                            bit_count <= bit_count + 1'b1;
                        end
                    end
                end
                
                PHY_ADDR: begin
                    // Send PHY address (5 bits)
                    mdio_out <= shift_reg[27-bit_count];
                    mdio_clk <= ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // On rising edge of MDC
                        if (next_state_change) begin
                            state <= REG_ADDR;
                            bit_count <= 6'd0;
                        end else begin
                            bit_count <= bit_count + 1'b1;
                        end
                    end
                end
                
                REG_ADDR: begin
                    // Send register address (5 bits)
                    mdio_out <= shift_reg[22-bit_count];
                    mdio_clk <= ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // On rising edge of MDC
                        if (next_state_change) begin
                            state <= TA;
                            bit_count <= 6'd0;
                        end else begin
                            bit_count <= bit_count + 1'b1;
                        end
                    end
                end
                
                TA: begin
                    // Turnaround (2 bits: 10 for write, Z0 for read)
                    // Simplified control logic with direct bit selection
                    mdio_oe <= !(read_req_reg && bit_count == 1);
                    mdio_out <= shift_reg[17-bit_count];
                    mdio_clk <= ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // On rising edge of MDC
                        if (next_state_change) begin
                            state <= DATA;
                            bit_count <= 6'd0;
                        end else begin
                            bit_count <= bit_count + 1'b1;
                        end
                    end
                end
                
                DATA: begin
                    // Unified data handling for both read and write
                    if (write_req_reg) begin
                        mdio_out <= shift_reg[15-bit_count];
                    end else if (mdio_clk == 1'b1) begin
                        // Sample on falling edge to maximize setup time
                        read_data[15-bit_count] <= mdio_data;
                    end
                    
                    mdio_clk <= ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // On rising edge of MDC
                        if (next_state_change) begin
                            state <= DONE;
                        end else begin
                            bit_count <= bit_count + 1'b1;
                        end
                    end
                end
                
                DONE: begin
                    mdio_clk <= 1'b1;
                    mdio_oe <= 1'b0;
                    ready <= 1'b1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule