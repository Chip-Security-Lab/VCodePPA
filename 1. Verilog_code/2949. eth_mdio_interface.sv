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
    localparam IDLE = 3'd0, START = 3'd1, OP = 3'd2, PHY_ADDR = 3'd3;
    localparam REG_ADDR = 3'd4, TA = 3'd5, DATA = 3'd6, DONE = 3'd7;
    
    reg [2:0] state;
    reg [5:0] bit_count;
    reg [31:0] shift_reg;
    reg mdio_out;
    reg mdio_oe; // Output enable for MDIO data
    
    // MDIO is a bidirectional signal
    assign mdio_data = mdio_oe ? mdio_out : 1'bz;
    
    // MDIO clock divider (host clock / 2)
    reg mdio_clk_div;
    always @(posedge clk or posedge reset) begin
        if (reset)
            mdio_clk_div <= 1'b0;
        else
            mdio_clk_div <= ~mdio_clk_div;
    end
    
    // State machine
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
        end else if (mdio_clk_div) begin // Only update on MDC clock edge
            case (state)
                IDLE: begin
                    mdio_clk <= 1'b1;
                    mdio_oe <= 1'b0;
                    
                    if (read_req) begin
                        // Format: <Preamble><ST><OP><PHYAD><REGAD><TA><DATA>
                        shift_reg <= {32'hFFFFFFFF, 2'b01, 2'b10, phy_addr, reg_addr, 2'b00, 16'h0000};
                        state <= START;
                        bit_count <= 6'd0;
                        ready <= 1'b0;
                        error <= 1'b0;
                        mdio_oe <= 1'b1;
                    end else if (write_req) begin
                        shift_reg <= {32'hFFFFFFFF, 2'b01, 2'b01, phy_addr, reg_addr, 2'b10, write_data};
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
                        if (bit_count == 31) begin
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
                        if (bit_count == 3) begin
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
                        if (bit_count == 4) begin
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
                        if (bit_count == 4) begin
                            state <= TA;
                            bit_count <= 6'd0;
                        end else begin
                            bit_count <= bit_count + 1'b1;
                        end
                    end
                end
                
                TA: begin
                    // Turnaround (2 bits: 10 for write, Z0 for read)
                    if (read_req && bit_count == 1)
                        mdio_oe <= 1'b0; // Release bus for READ operation
                    else
                        mdio_out <= shift_reg[17-bit_count];
                        
                    mdio_clk <= ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // On rising edge of MDC
                        if (bit_count == 1) begin
                            state <= DATA;
                            bit_count <= 6'd0;
                        end else begin
                            bit_count <= bit_count + 1'b1;
                        end
                    end
                end
                
                DATA: begin
                    if (write_req) begin
                        // Send write data (16 bits)
                        mdio_out <= shift_reg[15-bit_count];
                    end else begin
                        // Read data (16 bits)
                        if (mdio_clk == 1'b1) // On falling edge of MDC
                            read_data[15-bit_count] <= mdio_data;
                    end
                    
                    mdio_clk <= ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // On rising edge of MDC
                        if (bit_count == 15) begin
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