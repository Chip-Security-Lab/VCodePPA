//SystemVerilog
module dual_port_rom (
    input clk,
    input rst_n,
    
    // Port A interface
    input [3:0] addr_a,
    input valid_a,
    output reg ready_a,
    output reg [7:0] data_a,
    output reg valid_data_a,
    input ready_data_a,
    
    // Port B interface
    input [3:0] addr_b,
    input valid_b,
    output reg ready_b,
    output reg [7:0] data_b,
    output reg valid_data_b,
    input ready_data_b
);
    reg [7:0] rom [0:15];
    
    // Pipeline stage 1: Address input registers
    reg [3:0] addr_a_stage1, addr_b_stage1;
    reg addr_a_valid_stage1, addr_b_valid_stage1;
    
    // Pipeline stage 2: Address decoding registers
    reg [3:0] addr_a_stage2, addr_b_stage2;
    reg addr_a_valid_stage2, addr_b_valid_stage2;
    
    // Pipeline stage 3: Data fetching registers
    reg [7:0] data_a_stage3, data_b_stage3;
    reg addr_a_valid_stage3, addr_b_valid_stage3;
    
    initial begin
        rom[0] = 8'h12; rom[1] = 8'h34; rom[2] = 8'h56; rom[3] = 8'h78;
        rom[4] = 8'h9A; rom[5] = 8'hBC; rom[6] = 8'hDE; rom[7] = 8'hF0;
        rom[8] = 8'h11; rom[9] = 8'h22; rom[10] = 8'h33; rom[11] = 8'h44;
        rom[12] = 8'h55; rom[13] = 8'h66; rom[14] = 8'h77; rom[15] = 8'h88;
    end

    // Port A control logic - Stage 1: Address capture
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_a <= 1'b1;
            addr_a_valid_stage1 <= 1'b0;
            addr_a_stage1 <= 4'b0;
        end else begin
            if (valid_a && ready_a) begin
                addr_a_stage1 <= addr_a;
                addr_a_valid_stage1 <= 1'b1;
                ready_a <= ready_data_a; // Backpressure from output
            end else if (valid_data_a && ready_data_a) begin
                addr_a_valid_stage1 <= 1'b0;
                ready_a <= 1'b1;
            end
        end
    end

    // Port B control logic - Stage 1: Address capture
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_b <= 1'b1;
            addr_b_valid_stage1 <= 1'b0;
            addr_b_stage1 <= 4'b0;
        end else begin
            if (valid_b && ready_b) begin
                addr_b_stage1 <= addr_b;
                addr_b_valid_stage1 <= 1'b1;
                ready_b <= ready_data_b; // Backpressure from output
            end else if (valid_data_b && ready_data_b) begin
                addr_b_valid_stage1 <= 1'b0;
                ready_b <= 1'b1;
            end
        end
    end

    // Stage 2: Address decoding pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_a_stage2 <= 4'b0;
            addr_b_stage2 <= 4'b0;
            addr_a_valid_stage2 <= 1'b0;
            addr_b_valid_stage2 <= 1'b0;
        end else begin
            // Forward address and valid signals to stage 2
            addr_a_stage2 <= addr_a_stage1;
            addr_b_stage2 <= addr_b_stage1;
            addr_a_valid_stage2 <= addr_a_valid_stage1 && !valid_data_a;
            addr_b_valid_stage2 <= addr_b_valid_stage1 && !valid_data_b;
        end
    end
    
    // Stage 3: Data fetching pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_a_stage3 <= 8'b0;
            data_b_stage3 <= 8'b0;
            addr_a_valid_stage3 <= 1'b0;
            addr_b_valid_stage3 <= 1'b0;
        end else begin
            // Port A data fetching
            if (addr_a_valid_stage2) begin
                data_a_stage3 <= rom[addr_a_stage2];
                addr_a_valid_stage3 <= 1'b1;
            end else if (valid_data_a && ready_data_a) begin
                addr_a_valid_stage3 <= 1'b0;
            end
            
            // Port B data fetching
            if (addr_b_valid_stage2) begin
                data_b_stage3 <= rom[addr_b_stage2];
                addr_b_valid_stage3 <= 1'b1;
            end else if (valid_data_b && ready_data_b) begin
                addr_b_valid_stage3 <= 1'b0;
            end
        end
    end

    // Stage 4: Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_a <= 8'b0;
            valid_data_a <= 1'b0;
            data_b <= 8'b0;
            valid_data_b <= 1'b0;
        end else begin
            // Port A output handling
            if (addr_a_valid_stage3 && !valid_data_a) begin
                data_a <= data_a_stage3;
                valid_data_a <= 1'b1;
            end else if (valid_data_a && ready_data_a) begin
                valid_data_a <= 1'b0;
            end
            
            // Port B output handling
            if (addr_b_valid_stage3 && !valid_data_b) begin
                data_b <= data_b_stage3;
                valid_data_b <= 1'b1;
            end else if (valid_data_b && ready_data_b) begin
                valid_data_b <= 1'b0;
            end
        end
    end
endmodule