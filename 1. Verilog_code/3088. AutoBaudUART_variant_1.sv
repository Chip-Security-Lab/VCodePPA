//SystemVerilog
module AutoBaudUART (
    // Clock and Reset
    input wire clk,
    input wire rst_n,
    
    // UART RX Line
    input wire rx_line,
    
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
    input wire s_axil_rready
);

    // AXI4-Lite response codes
    localparam RESP_OKAY = 2'b00;
    localparam RESP_ERROR = 2'b10;
    
    // Register Offsets
    localparam BAUD_RATE_REG = 4'h0;
    localparam STATUS_REG = 4'h4;
    
    // Internal signals
    localparam SEARCH = 2'b00, MEASURE = 2'b01, LOCKED = 2'b10;
    reg [1:0] current_state, next_state;
    
    // Pipeline registers
    reg [15:0] edge_counter_stage1, edge_counter_stage2;
    reg last_rx_stage1, last_rx_stage2;
    reg rx_line_stage1, rx_line_stage2;
    
    // Internal registers
    reg [15:0] baud_rate_stage1, baud_rate_stage2;
    reg baud_locked_stage1, baud_locked_stage2;
    
    // AXI4-Lite write channel registers
    reg [3:0] write_addr_stage1, write_addr_stage2;
    reg write_valid_stage1, write_valid_stage2;
    reg [31:0] write_data_stage1, write_data_stage2;
    
    // AXI4-Lite read channel registers
    reg [3:0] read_addr_stage1, read_addr_stage2;
    reg read_valid_stage1, read_valid_stage2;
    
    // Write Address Channel Pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_awready <= 1'b0;
            write_addr_stage1 <= 4'h0;
            write_valid_stage1 <= 1'b0;
            write_addr_stage2 <= 4'h0;
            write_valid_stage2 <= 1'b0;
        end else begin
            // Stage 1
            if (s_axil_awvalid && !s_axil_awready) begin
                s_axil_awready <= 1'b1;
                write_addr_stage1 <= s_axil_awaddr[3:0];
            end else begin
                s_axil_awready <= 1'b0;
            end
            
            // Stage 2
            write_addr_stage2 <= write_addr_stage1;
            if (s_axil_wvalid && s_axil_wready) begin
                write_valid_stage2 <= 1'b1;
            end else if (write_valid_stage2) begin
                write_valid_stage2 <= 1'b0;
            end
        end
    end
    
    // Write Data Channel Pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_wready <= 1'b0;
            write_data_stage1 <= 32'h0;
            write_data_stage2 <= 32'h0;
        end else begin
            // Stage 1
            if (s_axil_wvalid && !s_axil_wready) begin
                s_axil_wready <= 1'b1;
                write_data_stage1 <= s_axil_wdata;
            end else begin
                s_axil_wready <= 1'b0;
            end
            
            // Stage 2
            write_data_stage2 <= write_data_stage1;
        end
    end
    
    // Write Response Channel Pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= RESP_OKAY;
        end else begin
            if (write_valid_stage2 && !s_axil_bvalid) begin
                s_axil_bvalid <= 1'b1;
                if (write_addr_stage2 == STATUS_REG && s_axil_wstrb[0]) begin
                    s_axil_bresp <= RESP_OKAY;
                end else begin
                    s_axil_bresp <= RESP_ERROR;
                end
            end else if (s_axil_bvalid && s_axil_bready) begin
                s_axil_bvalid <= 1'b0;
            end
        end
    end
    
    // Read Address Channel Pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_arready <= 1'b0;
            read_addr_stage1 <= 4'h0;
            read_valid_stage1 <= 1'b0;
            read_addr_stage2 <= 4'h0;
            read_valid_stage2 <= 1'b0;
        end else begin
            // Stage 1
            if (s_axil_arvalid && !s_axil_arready) begin
                s_axil_arready <= 1'b1;
                read_addr_stage1 <= s_axil_araddr[3:0];
                read_valid_stage1 <= 1'b1;
            end else begin
                s_axil_arready <= 1'b0;
            end
            
            // Stage 2
            read_addr_stage2 <= read_addr_stage1;
            read_valid_stage2 <= read_valid_stage1;
            if (s_axil_rvalid && s_axil_rready) begin
                read_valid_stage2 <= 1'b0;
            end
        end
    end
    
    // Read Data Channel Pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_rvalid <= 1'b0;
            s_axil_rdata <= 32'h0;
            s_axil_rresp <= RESP_OKAY;
        end else begin
            if (read_valid_stage2 && !s_axil_rvalid) begin
                s_axil_rvalid <= 1'b1;
                case (read_addr_stage2)
                    BAUD_RATE_REG: begin
                        s_axil_rdata <= {16'h0, baud_rate_stage2};
                        s_axil_rresp <= RESP_OKAY;
                    end
                    STATUS_REG: begin
                        s_axil_rdata <= {31'h0, baud_locked_stage2};
                        s_axil_rresp <= RESP_OKAY;
                    end
                    default: begin
                        s_axil_rdata <= 32'h0;
                        s_axil_rresp <= RESP_ERROR;
                    end
                endcase
            end else if (s_axil_rvalid && s_axil_rready) begin
                s_axil_rvalid <= 1'b0;
            end
        end
    end
    
    // Core UART Auto-baud logic Pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= SEARCH;
            next_state <= SEARCH;
            edge_counter_stage1 <= 16'h0;
            edge_counter_stage2 <= 16'h0;
            last_rx_stage1 <= 1'b1;
            last_rx_stage2 <= 1'b1;
            rx_line_stage1 <= 1'b1;
            rx_line_stage2 <= 1'b1;
            baud_locked_stage1 <= 1'b0;
            baud_locked_stage2 <= 1'b0;
            baud_rate_stage1 <= 16'h0;
            baud_rate_stage2 <= 16'h0;
        end else begin
            // Stage 1: Input sampling and state transition
            rx_line_stage1 <= rx_line;
            last_rx_stage1 <= rx_line_stage1;
            
            if (write_valid_stage2 && write_addr_stage2 == STATUS_REG && s_axil_wstrb[0]) begin
                if (write_data_stage2[0] == 1'b0) begin
                    next_state <= SEARCH;
                    baud_locked_stage1 <= 1'b0;
                end
            end else begin
                case(current_state)
                    SEARCH: begin
                        if (last_rx_stage1 == 1'b1 && rx_line_stage1 == 1'b0) begin
                            next_state <= MEASURE;
                            edge_counter_stage1 <= 16'h0;
                        end else begin
                            next_state <= SEARCH;
                        end
                    end
                    MEASURE: begin
                        edge_counter_stage1 <= edge_counter_stage1 + 16'h1;
                        if (last_rx_stage1 == 1'b0 && rx_line_stage1 == 1'b1) begin
                            next_state <= LOCKED;
                            baud_rate_stage1 <= edge_counter_stage1;
                        end else begin
                            next_state <= MEASURE;
                        end
                    end
                    LOCKED: begin
                        next_state <= LOCKED;
                        baud_locked_stage1 <= 1'b1;
                    end
                    default: next_state <= SEARCH;
                endcase
            end
            
            // Stage 2: State and data update
            current_state <= next_state;
            edge_counter_stage2 <= edge_counter_stage1;
            last_rx_stage2 <= last_rx_stage1;
            rx_line_stage2 <= rx_line_stage1;
            baud_locked_stage2 <= baud_locked_stage1;
            baud_rate_stage2 <= baud_rate_stage1;
        end
    end
endmodule