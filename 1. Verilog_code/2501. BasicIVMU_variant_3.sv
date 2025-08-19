// Submodule: priority_encoder
// Description: Finds the index of the highest active bit in int_req
module priority_encoder (
    input wire [7:0] int_req,
    output reg [2:0] priority_index,
    output reg any_request
);

    // Combinational logic to determine the highest priority index and if any request is active
    always @* begin
        any_request = |int_req; // Check if any request is high
        
        // Default index if no request is high (can be 0 or don't care, 0 is a safe default)
        priority_index = 3'b000; 
        
        // Priority encoding (highest index first)
        if (int_req[7]) begin
            priority_index = 3'd7;
        end else if (int_req[6]) begin
            priority_index = 3'd6;
        end else if (int_req[5]) begin
            priority_index = 3'd5;
        end else if (int_req[4]) begin
            priority_index = 3'd4;
        end else if (int_req[3]) begin
            priority_index = 3'd3;
        end else if (int_req[2]) begin
            priority_index = 3'd2;
        end else if (int_req[1]) begin
            priority_index = 3'd1;
        end else if (int_req[0]) begin
            priority_index = 3'd0;
        end
        // If any_request is 0, priority_index will be 0. 
        // The top module handles the case where any_request is 0 by setting vector_addr to 0 and int_valid to 0.
        // So the default priority_index of 0 when no request is fine.
    end

endmodule

// Top Module: BasicIVMU_refactored
// Description: Refactored Interrupt Vector Unit using a priority encoder submodule
module BasicIVMU_refactored (
    input wire clk, rst_n,
    input wire [7:0] int_req,
    output reg [31:0] vector_addr,
    output reg int_valid
);

    // Internal vector table storage
    reg [31:0] vec_table [0:7];
    integer i;
    
    // Initialize vector table
    initial begin
        for (i = 0; i < 8; i = i + 1)
            vec_table[i] = 32'h1000_0000 + (i << 2);
    end

    // Wires to connect to priority encoder submodule
    wire [2:0] selected_index;
    wire any_interrupt_pending;

    // Instantiate the priority encoder submodule
    priority_encoder priority_enc_inst (
        .int_req(int_req),
        .priority_index(selected_index),
        .any_request(any_interrupt_pending)
    );

    // Combinational logic to select the vector address based on the index
    // This performs the lookup from the vector table
    wire [31:0] next_vector_addr;
    
    assign next_vector_addr = vec_table[selected_index]; // Direct lookup using the selected index

    // Sequential logic to register the final outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Asynchronous reset
            vector_addr <= 32'h0;
            int_valid <= 1'b0;
        end else begin
            // Update outputs on the clock edge based on the combinational results
            if (any_interrupt_pending) begin
                vector_addr <= next_vector_addr;
                int_valid <= 1'b1;
            end else begin
                // No interrupt request is active
                vector_addr <= 32'h0; // Default address when no request
                int_valid <= 1'b0;
            end
        end
    end

endmodule