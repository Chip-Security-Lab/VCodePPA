//SystemVerilog
module debounce_recovery_axi4lite (
    // Global signals
    input wire ACLK,
    input wire ARESETn,
    
    // Write address channel
    input wire [31:0] AWADDR,
    input wire AWVALID,
    output reg AWREADY,
    
    // Write data channel
    input wire [31:0] WDATA,
    input wire [3:0] WSTRB,
    input wire WVALID,
    output reg WREADY,
    
    // Write response channel
    output reg [1:0] BRESP,
    output reg BVALID,
    input wire BREADY,
    
    // Read address channel
    input wire [31:0] ARADDR,
    input wire ARVALID,
    output reg ARREADY,
    
    // Read data channel
    output reg [31:0] RDATA,
    output reg [1:0] RRESP,
    output reg RVALID,
    input wire RREADY,
    
    // Original signal interface
    input wire noisy_signal,
    output wire clean_signal
);

    // Internal registers
    reg [15:0] count;
    reg sync_1, sync_2;
    reg clean_signal_reg;
    
    // AXI4-Lite FSM states
    localparam [1:0] 
        IDLE = 2'b00,
        READ = 2'b01,
        WRITE = 2'b10;
    
    reg [1:0] state;
    
    // Debounce logic (same as original)
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            sync_1 <= 1'b0;
            sync_2 <= 1'b0;
            count <= 16'h0000;
            clean_signal_reg <= 1'b0;
        end else begin
            sync_1 <= noisy_signal;
            sync_2 <= sync_1;
            
            if (sync_2 != clean_signal_reg) begin
                count <= count + 16'h0001;
                if (count == 16'hFFFF) begin
                    clean_signal_reg <= sync_2;
                    count <= 16'h0000;
                end
            end else begin
                count <= 16'h0000;
            end
        end
    end
    
    assign clean_signal = clean_signal_reg;
    
    // AXI4-Lite write FSM
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            state <= IDLE;
            AWREADY <= 1'b0;
            WREADY <= 1'b0;
            BVALID <= 1'b0;
            BRESP <= 2'b00;
        end else begin
            case (state)
                IDLE: begin
                    if (AWVALID && WVALID) begin
                        AWREADY <= 1'b1;
                        WREADY <= 1'b1;
                        state <= WRITE;
                    end else if (ARVALID) begin
                        ARREADY <= 1'b1;
                        state <= READ;
                    end
                end
                
                WRITE: begin
                    AWREADY <= 1'b0;
                    WREADY <= 1'b0;
                    BVALID <= 1'b1;
                    BRESP <= 2'b00; // OKAY response
                    if (BREADY) begin
                        BVALID <= 1'b0;
                        state <= IDLE;
                    end
                end
                
                READ: begin
                    ARREADY <= 1'b0;
                    RVALID <= 1'b1;
                    RRESP <= 2'b00; // OKAY response
                    RDATA <= {16'h0000, clean_signal_reg, 15'h0000};
                    if (RREADY) begin
                        RVALID <= 1'b0;
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule