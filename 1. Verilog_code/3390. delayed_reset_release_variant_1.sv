//SystemVerilog
//IEEE 1364-2005 Verilog
module delayed_reset_release(
    // Clock and Reset
    input wire aclk,
    input wire aresetn,
    
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
    input wire s_axil_rready,
    
    // Original output
    output reg reset_out
);

    // Internal registers for delay reset logic
    reg [3:0] delay_value;
    reg [3:0] counter;
    reg reset_in;
    
    // Register address mapping (byte addressing)
    localparam ADDR_DELAY_VALUE = 4'h0;
    localparam ADDR_RESET_CONTROL = 4'h4;
    localparam ADDR_STATUS = 4'h8;
    
    // AXI4-Lite write transaction states
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    
    // AXI4-Lite read transaction states
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;
    
    // State registers
    reg [1:0] write_state, write_next;
    reg [1:0] read_state, read_next;
    
    reg [31:0] write_addr;
    reg [31:0] read_addr;
    
    // Combinational logic for FSM next states
    always @(*) begin
        // Write FSM next state logic
        write_next = write_state;
        
        case (write_state)
            WRITE_IDLE: begin
                if (s_axil_awvalid) 
                    write_next = WRITE_ADDR;
            end
            
            WRITE_ADDR: begin
                if (s_axil_wvalid)
                    write_next = WRITE_DATA;
            end
            
            WRITE_DATA: begin
                write_next = WRITE_RESP;
            end
            
            WRITE_RESP: begin
                if (s_axil_bready)
                    write_next = WRITE_IDLE;
            end
        endcase
        
        // Read FSM next state logic
        read_next = read_state;
        
        case (read_state)
            READ_IDLE: begin
                if (s_axil_arvalid)
                    read_next = READ_ADDR;
            end
            
            READ_ADDR: begin
                read_next = READ_DATA;
            end
            
            READ_DATA: begin
                if (s_axil_rready && s_axil_rvalid)
                    read_next = READ_IDLE;
            end
        endcase
    end
    
    // Sequential logic for clock domain
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            // Write interface reset
            write_state <= WRITE_IDLE;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
            write_addr <= 32'h0;
            
            // Read interface reset
            read_state <= READ_IDLE;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= 2'b00;
            s_axil_rdata <= 32'h0;
            read_addr <= 32'h0;
            
            // Reset logic reset
            delay_value <= 4'h0;
            reset_in <= 1'b0;
            counter <= 4'h0;
            reset_out <= 1'b0;
        end else begin
            // State registers update
            write_state <= write_next;
            read_state <= read_next;
            
            // Write interface logic
            case (write_state)
                WRITE_IDLE: begin
                    s_axil_awready <= 1'b1;
                    s_axil_wready <= 1'b0;
                    s_axil_bvalid <= 1'b0;
                end
                
                WRITE_ADDR: begin
                    if (s_axil_awvalid && s_axil_awready) begin
                        write_addr <= s_axil_awaddr;
                        s_axil_awready <= 1'b0;
                        s_axil_wready <= 1'b1;
                    end
                end
                
                WRITE_DATA: begin
                    if (s_axil_wvalid && s_axil_wready) begin
                        s_axil_wready <= 1'b0;
                        s_axil_bvalid <= 1'b1;
                        s_axil_bresp <= 2'b00; // OKAY response
                        
                        // Register write operations
                        case (write_addr[3:0])
                            ADDR_DELAY_VALUE: begin
                                if (s_axil_wstrb[0])
                                    delay_value <= s_axil_wdata[3:0];
                            end
                            
                            ADDR_RESET_CONTROL: begin
                                if (s_axil_wstrb[0])
                                    reset_in <= s_axil_wdata[0];
                            end
                            
                            default: begin
                                // Invalid address, but still acknowledge
                                s_axil_bresp <= 2'b10; // SLVERR response
                            end
                        endcase
                    end
                end
                
                WRITE_RESP: begin
                    if (s_axil_bready && s_axil_bvalid)
                        s_axil_bvalid <= 1'b0;
                end
            endcase
            
            // Read interface logic
            case (read_state)
                READ_IDLE: begin
                    s_axil_arready <= 1'b1;
                    s_axil_rvalid <= 1'b0;
                end
                
                READ_ADDR: begin
                    if (s_axil_arvalid && s_axil_arready) begin
                        read_addr <= s_axil_araddr;
                        s_axil_arready <= 1'b0;
                    end
                end
                
                READ_DATA: begin
                    s_axil_rvalid <= 1'b1;
                    s_axil_rresp <= 2'b00; // OKAY response
                    
                    // Register read operations
                    case (read_addr[3:0])
                        ADDR_DELAY_VALUE: begin
                            s_axil_rdata <= {28'h0, delay_value};
                        end
                        
                        ADDR_RESET_CONTROL: begin
                            s_axil_rdata <= {31'h0, reset_in};
                        end
                        
                        ADDR_STATUS: begin
                            s_axil_rdata <= {27'h0, counter, reset_out};
                        end
                        
                        default: begin
                            s_axil_rdata <= 32'h0;
                            s_axil_rresp <= 2'b10; // SLVERR response
                        end
                    endcase
                    
                    if (s_axil_rready && s_axil_rvalid) begin
                        s_axil_rvalid <= 1'b0;
                    end
                end
            endcase
            
            // Core reset delay functionality
            if (reset_in) begin
                counter <= delay_value;
                reset_out <= 1'b1;
            end else if (counter > 0) begin
                counter <= counter - 1'b1;
                reset_out <= 1'b1;
            end else begin
                reset_out <= 1'b0;
            end
        end
    end

endmodule